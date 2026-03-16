#!/usr/bin/env python3
"""
Lab Controller - Auto-unlock daemon + web slides + solution guide server.

- Monitors CTFd solve progress
- Auto-unlocks next category when threshold met
- Serves reveal.js slides at /slides
- Serves password-gated solution guide at /solutions
"""

import os
import json
import time
import threading
from http.server import HTTPServer, SimpleHTTPRequestHandler
from urllib.request import Request, urlopen
from urllib.error import URLError
import base64

# --- CONFIG ---
CTFD_URL = os.environ.get("CTFD_URL", "http://ctfd:8000")
CTFD_ADMIN_USER = os.environ.get("CTFD_ADMIN_USER", "admin")
CTFD_ADMIN_PASS = os.environ.get("CTFD_ADMIN_PASS", "NmapLab2024!")
UNLOCK_THRESHOLD = float(os.environ.get("UNLOCK_THRESHOLD", "0.5"))  # 50% of category solved
SOLUTION_PASSWORD = os.environ.get("SOLUTION_PASSWORD", "instructor2024")
POLL_INTERVAL = int(os.environ.get("POLL_INTERVAL", "10"))
START_LOCKED = os.environ.get("START_LOCKED", "true").lower() == "true"
PORT = int(os.environ.get("CONTROLLER_PORT", "8080"))
CTF_DURATION = int(os.environ.get("CTF_DURATION_MINUTES", "120"))
CTF_EXTEND = int(os.environ.get("CTF_EXTEND_MINUTES", "60"))

# Timer state
ctf_start_time = None   # Set when first real category unlocks
ctf_end_time = None      # start + duration

# Category unlock order
CATEGORY_ORDER = [
    "Knowledge Check",    # Unlocked from start (multi-choice during lecture)
    "Host Discovery",     # First hands-on
    "Port Scanning",      # After Host Discovery
    "Service Detection",  # After Port Scanning
    "Advanced Recon",     # After Service Detection
    "Deep Dive",          # Final boss - time sinks
]

api_token = None


def log(msg):
    print(f"[controller] {msg}", flush=True)


# ==========================================================================
# CTFd API helpers
# ==========================================================================
def ctfd_request(path, method="GET", data=None, headers=None):
    """Make a request to CTFd API."""
    url = f"{CTFD_URL}/api/v1{path}"
    hdrs = {"Content-Type": "application/json"}
    if api_token:
        hdrs["Authorization"] = f"Token {api_token}"
    if headers:
        hdrs.update(headers)
    body = json.dumps(data).encode() if data else None
    req = Request(url, data=body, headers=hdrs, method=method)
    try:
        with urlopen(req, timeout=10) as resp:
            return json.loads(resp.read())
    except Exception as e:
        log(f"API error: {path} -> {e}")
        return None


def wait_for_ctfd():
    """Wait for CTFd to be ready and get API token."""
    global api_token
    log("Waiting for CTFd...")
    for _ in range(120):
        try:
            # Try to reach CTFd
            req = Request(f"{CTFD_URL}/api/v1/challenges", headers={"Content-Type": "application/json"})
            with urlopen(req, timeout=5):
                pass
            break
        except Exception:
            time.sleep(2)
    else:
        log("CTFd not reachable after 240s")
        return False

    # Login and get token
    log("Authenticating with CTFd...")
    for _ in range(30):
        try:
            # Get nonce from login page
            with urlopen(f"{CTFD_URL}/login", timeout=5) as resp:
                page = resp.read().decode()
                # Extract nonce
                import re
                match = re.search(r'name="nonce"[^>]*value="([^"]+)"', page)
                if not match:
                    time.sleep(5)
                    continue
                nonce = match.group(1)
                cookie_header = resp.headers.get("Set-Cookie", "")

            # Login
            login_data = f"name={CTFD_ADMIN_USER}&password={CTFD_ADMIN_PASS}&nonce={nonce}".encode()
            login_req = Request(
                f"{CTFD_URL}/login",
                data=login_data,
                headers={
                    "Content-Type": "application/x-www-form-urlencoded",
                    "Cookie": cookie_header.split(";")[0] if cookie_header else "",
                },
                method="POST",
            )
            try:
                with urlopen(login_req, timeout=10) as resp:
                    session_cookie = resp.headers.get("Set-Cookie", cookie_header)
            except Exception:
                # 302 redirect is expected
                pass

            # Get CSRF from admin page
            admin_req = Request(
                f"{CTFD_URL}/admin/statistics",
                headers={"Cookie": session_cookie.split(";")[0] if session_cookie else ""},
            )
            with urlopen(admin_req, timeout=10) as resp:
                admin_page = resp.read().decode()
                csrf_match = re.search(r"csrfNonce.*?:\s*\"([a-f0-9]+)\"", admin_page)
                if not csrf_match:
                    time.sleep(5)
                    continue
                csrf = csrf_match.group(1)

            # Generate API token
            token_req = Request(
                f"{CTFD_URL}/api/v1/tokens",
                data=json.dumps({"description": "lab-controller"}).encode(),
                headers={
                    "Content-Type": "application/json",
                    "Cookie": session_cookie.split(";")[0],
                    "CSRF-Token": csrf,
                },
                method="POST",
            )
            with urlopen(token_req, timeout=10) as resp:
                token_data = json.loads(resp.read())
                api_token = token_data["data"]["value"]
                log(f"Authenticated. Token: {api_token[:20]}...")
                return True
        except Exception as e:
            log(f"Auth attempt failed: {e}")
            time.sleep(5)

    log("Could not authenticate with CTFd")
    return False


def get_challenges():
    """Get all challenges grouped by category."""
    resp = ctfd_request("/challenges?view=admin")
    if not resp or not resp.get("success"):
        return {}
    by_cat = {}
    for c in resp["data"]:
        cat = c["category"]
        if cat not in by_cat:
            by_cat[cat] = []
        by_cat[cat].append(c)
    return by_cat


def get_solves():
    """Get solve counts per challenge."""
    resp = ctfd_request("/challenges")
    if not resp or not resp.get("success"):
        return {}
    return {c["id"]: c.get("solves", 0) for c in resp["data"]}


def set_category_state(challenges_by_cat, category, state):
    """Set all challenges in a category to visible/hidden."""
    if category not in challenges_by_cat:
        return
    for c in challenges_by_cat[category]:
        if c["state"] != state:
            ctfd_request(f"/challenges/{c['id']}", method="PATCH", data={"state": state})
            log(f"  {c['name']} -> {state}")


def lock_all(challenges_by_cat):
    """Hide all challenges."""
    log("Locking all challenges...")
    for cat in CATEGORY_ORDER:
        set_category_state(challenges_by_cat, cat, "hidden")
    log("All challenges locked")


def get_category_completion(challenges_by_cat, solves, category):
    """Return fraction of challenges solved in a category (any team)."""
    if category not in challenges_by_cat:
        return 0.0
    challenges = challenges_by_cat[category]
    if not challenges:
        return 0.0
    solved = sum(1 for c in challenges if solves.get(c["id"], 0) > 0)
    return solved / len(challenges)


# ==========================================================================
# Auto-unlock daemon
# ==========================================================================
def unlock_daemon():
    """Monitor solves and auto-unlock next category."""
    if not wait_for_ctfd():
        log("Cannot start unlock daemon - CTFd auth failed")
        return

    # Wait for setup.sh to finish creating challenges
    log("Waiting for challenges to be seeded...")
    for _ in range(60):
        challenges = get_challenges()
        total = sum(len(v) for v in challenges.values())
        if total >= 20:  # We expect 30 but at least 20 means setup ran
            break
        time.sleep(5)

    challenges = get_challenges()
    log(f"Found {sum(len(v) for v in challenges.values())} challenges in {len(challenges)} categories")

    # Lock everything initially if configured
    if START_LOCKED:
        lock_all(challenges)
        # Unlock Knowledge Check immediately (multiple choice during lecture)
        set_category_state(challenges, "Knowledge Check", "visible")
        log("Knowledge Check unlocked (available during lecture)")

    unlocked = {"Knowledge Check"}
    log("Unlock daemon running...")

    while True:
        time.sleep(POLL_INTERVAL)

        try:
            challenges = get_challenges()
            solves = get_solves()

            for i, cat in enumerate(CATEGORY_ORDER):
                if cat in unlocked:
                    continue

                # First real category (Host Discovery) unlocks when instructor triggers
                # or after a delay. For auto-progression, check previous category.
                if i == 0:
                    continue  # Knowledge Check already unlocked

                prev_cat = CATEGORY_ORDER[i - 1]
                if prev_cat not in unlocked:
                    continue

                completion = get_category_completion(challenges, solves, prev_cat)
                if completion >= UNLOCK_THRESHOLD:
                    log(f"Unlocking '{cat}' ({prev_cat} at {completion:.0%} complete)")
                    set_category_state(challenges, cat, "visible")
                    unlocked.add(cat)

                    # Start timer on first real category unlock (after Knowledge Check)
                    if ctf_start_time is None and cat != "Knowledge Check":
                        import datetime
                        ctf_start_time = datetime.datetime.utcnow()
                        ctf_end_time = ctf_start_time + datetime.timedelta(minutes=CTF_DURATION)
                        log(f"CTF TIMER STARTED: {CTF_DURATION} min, ends {ctf_end_time.isoformat()}")
                        # Set CTFd freeze time
                        ctfd_request("/configs/freeze", method="PATCH",
                            data={"value": ctf_end_time.strftime("%Y-%m-%dT%H:%M:%S+00:00")})
        except Exception as e:
            log(f"Daemon error: {e}")


# ==========================================================================
# Web server for slides + solution guide
# ==========================================================================
class LabHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory="/app/static", **kwargs)

    def do_GET(self):
        global ctf_start_time, ctf_end_time
        import datetime

        # /slides -> serve slides
        if self.path == "/" or self.path.startswith("/slides"):
            self.path = "/slides.html"
            return super().do_GET()

        # /solutions -> password gated
        if self.path.startswith("/solutions"):
            auth = self.headers.get("Authorization", "")
            if auth:
                try:
                    creds = base64.b64decode(auth.split(" ")[1]).decode()
                    if creds == f"instructor:{SOLUTION_PASSWORD}":
                        self.path = "/solutions.html"
                        return super().do_GET()
                except Exception:
                    pass

            self.send_response(401)
            self.send_header("WWW-Authenticate", 'Basic realm="Instructor Solutions"')
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(b"<h2>Instructor login required</h2><p>Username: instructor</p>")
            return

        # /api/unlock/<category> -> manual unlock endpoint for instructor
        if self.path.startswith("/api/unlock/"):
            auth = self.headers.get("Authorization", "")
            authed = False
            if auth:
                try:
                    creds = base64.b64decode(auth.split(" ")[1]).decode()
                    if creds == f"instructor:{SOLUTION_PASSWORD}":
                        authed = True
                except Exception:
                    pass

            if not authed:
                self.send_response(401)
                self.send_header("WWW-Authenticate", 'Basic realm="Instructor"')
                self.end_headers()
                return

            category = self.path.replace("/api/unlock/", "").replace("%20", " ")
            challenges = get_challenges()
            set_category_state(challenges, category, "visible")
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "unlocked", "category": category}).encode())
            return

        # /api/timer -> get timer status (no auth, students can see)
        if self.path == "/api/timer":
            now = datetime.datetime.utcnow()
            data = {"started": False, "remaining": 0, "end_time": None}
            if ctf_end_time:
                remaining = max(0, int((ctf_end_time - now).total_seconds()))
                data = {
                    "started": True,
                    "remaining": remaining,
                    "end_time": ctf_end_time.isoformat() + "Z",
                    "expired": remaining == 0,
                }
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(json.dumps(data).encode())
            return

        # /api/extend -> add time (instructor auth required)
        if self.path == "/api/extend":
            auth = self.headers.get("Authorization", "")
            authed = False
            if auth:
                try:
                    creds = base64.b64decode(auth.split(" ")[1]).decode()
                    if creds == f"instructor:{SOLUTION_PASSWORD}":
                        authed = True
                except Exception:
                    pass
            if not authed:
                self.send_response(401)
                self.send_header("WWW-Authenticate", 'Basic realm="Instructor"')
                self.end_headers()
                return

            if ctf_end_time:
                ctf_end_time = ctf_end_time + datetime.timedelta(minutes=CTF_EXTEND)
                log(f"Timer extended by {CTF_EXTEND} min. New end: {ctf_end_time.isoformat()}")
                # Update CTFd freeze
                ctfd_request("/configs/freeze", method="PATCH",
                    data={"value": ctf_end_time.strftime("%Y-%m-%dT%H:%M:%S+00:00")})
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({
                    "status": "extended",
                    "added_minutes": CTF_EXTEND,
                    "new_end": ctf_end_time.isoformat() + "Z",
                }).encode())
            else:
                self.send_response(400)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(b'{"error":"Timer not started yet"}')
            return

        # /api/start -> manually start timer (instructor auth)
        if self.path == "/api/start":
            auth = self.headers.get("Authorization", "")
            authed = False
            if auth:
                try:
                    creds = base64.b64decode(auth.split(" ")[1]).decode()
                    if creds == f"instructor:{SOLUTION_PASSWORD}":
                        authed = True
                except Exception:
                    pass
            if not authed:
                self.send_response(401)
                self.send_header("WWW-Authenticate", 'Basic realm="Instructor"')
                self.end_headers()
                return

            ctf_start_time = datetime.datetime.utcnow()
            ctf_end_time = ctf_start_time + datetime.timedelta(minutes=CTF_DURATION)
            log(f"Timer MANUALLY started: {CTF_DURATION} min")
            ctfd_request("/configs/freeze", method="PATCH",
                data={"value": ctf_end_time.strftime("%Y-%m-%dT%H:%M:%S+00:00")})
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({
                "status": "started",
                "duration_minutes": CTF_DURATION,
                "end_time": ctf_end_time.isoformat() + "Z",
            }).encode())
            return

        # /api/lockall -> lock everything
        if self.path == "/api/lockall":
            auth = self.headers.get("Authorization", "")
            authed = False
            if auth:
                try:
                    creds = base64.b64decode(auth.split(" ")[1]).decode()
                    if creds == f"instructor:{SOLUTION_PASSWORD}":
                        authed = True
                except Exception:
                    pass
            if authed:
                challenges = get_challenges()
                lock_all(challenges)
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(b'{"status":"locked"}')
            else:
                self.send_response(401)
                self.send_header("WWW-Authenticate", 'Basic realm="Instructor"')
                self.end_headers()
            return

        # Everything else -> static files
        return super().do_GET()

    def log_message(self, format, *args):
        log(f"HTTP {args[0]}")


def web_server():
    server = HTTPServer(("0.0.0.0", PORT), LabHandler)
    log(f"Web server on port {PORT} (slides + solutions)")
    server.serve_forever()


# ==========================================================================
# Main
# ==========================================================================
if __name__ == "__main__":
    # Start web server in background
    web_thread = threading.Thread(target=web_server, daemon=True)
    web_thread.start()

    # Run unlock daemon in foreground
    unlock_daemon()
