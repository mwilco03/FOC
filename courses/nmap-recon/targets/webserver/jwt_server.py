#!/usr/bin/env python3
"""JWT challenge server on port 3000.
- GET / returns a guest JWT
- GET /admin with modified JWT (admin:true) returns the flag
- Secret is intentionally weak: 'secret'
"""

import json
import base64
import hashlib
import hmac
from http.server import HTTPServer, BaseHTTPRequestHandler

SECRET = "secret"  # Intentionally weak - students need to guess/crack this

def b64url_encode(data):
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()

def b64url_decode(s):
    s += "=" * (4 - len(s) % 4)
    return base64.urlsafe_b64decode(s)

def make_jwt(payload):
    header = b64url_encode(json.dumps({"alg": "HS256", "typ": "JWT"}).encode())
    body = b64url_encode(json.dumps(payload).encode())
    sig_input = f"{header}.{body}".encode()
    sig = b64url_encode(hmac.new(SECRET.encode(), sig_input, hashlib.sha256).digest())
    return f"{header}.{body}.{sig}"

def verify_jwt(token):
    try:
        parts = token.split(".")
        if len(parts) != 3:
            return None
        header, body, sig = parts
        # Verify signature
        expected = b64url_encode(hmac.new(SECRET.encode(), f"{header}.{body}".encode(), hashlib.sha256).digest())
        if not hmac.compare_digest(sig, expected):
            return None
        return json.loads(b64url_decode(body))
    except Exception:
        return None

class JWTHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/" or self.path == "/login":
            token = make_jwt({"user": "guest", "admin": False})
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(f"""<!DOCTYPE html>
<html><head><title>Corp Portal</title></head><body>
<h1>Corporate Portal</h1>
<p>Welcome, guest. Your access token:</p>
<pre style="word-break:break-all;background:#eee;padding:10px;">{token}</pre>
<p>Visit <a href="/admin">/admin</a> with your token to access the admin panel.</p>
<p>Send token as: <code>Authorization: Bearer &lt;token&gt;</code></p>
<p><small>Hint: JWTs are base64-encoded JSON. The secret might be simple...</small></p>
<!-- JWT secret is 'secret' — but students should figure this out -->
</body></html>""".encode())

        elif self.path.startswith("/admin"):
            auth = self.headers.get("Authorization", "")
            cookie = self.headers.get("Cookie", "")
            token = None

            if auth.startswith("Bearer "):
                token = auth[7:]
            elif "token=" in cookie:
                token = cookie.split("token=")[1].split(";")[0]
            # Also check query string
            elif "?token=" in self.path:
                token = self.path.split("?token=")[1]

            if not token:
                self.send_response(401)
                self.send_header("Content-Type", "text/html")
                self.end_headers()
                self.wfile.write(b"<h1>401 Unauthorized</h1><p>Send your JWT as Authorization: Bearer &lt;token&gt; or ?token=&lt;jwt&gt;</p>")
                return

            payload = verify_jwt(token)
            if payload is None:
                self.send_response(403)
                self.send_header("Content-Type", "text/html")
                self.end_headers()
                self.wfile.write(b"<h1>403 Forbidden</h1><p>Invalid token signature. Nice try.</p>")
                return

            if payload.get("admin") == True:
                self.send_response(200)
                self.send_header("Content-Type", "text/html")
                self.end_headers()
                self.wfile.write(b"<h1>Welcome, Admin!</h1><p>FLAG{jwt_admin_bypass}</p>")
            else:
                self.send_response(403)
                self.send_header("Content-Type", "text/html")
                self.end_headers()
                self.wfile.write(f"<h1>Access Denied</h1><p>You are: {payload.get('user', 'unknown')}</p><p>Admin access required. Your token says admin={payload.get('admin')}.</p>".encode())

        elif self.path == "/robots.txt":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"""User-agent: *
Disallow: /admin/
Disallow: /backup/
Disallow: /api/keys/
Disallow: /secret/
Disallow: /.git/
""")

        elif self.path == "/backup/" or self.path == "/backup":
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(b"<h1>Backup Directory</h1><pre>db_dump_2024.sql\nconfig.tar.gz\n</pre><!-- FLAG{robots_txt_reveals_all} -->")

        elif self.path == "/secret/" or self.path == "/secret":
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(b"<h1>Secret Area</h1><p>You found it by reading robots.txt, didn't you?</p>")

        elif self.path.startswith("/api/keys"):
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"api_key":"sk-prod-1234567890","note":"FLAG{api_keys_in_robots}"}')

        else:
            self.send_response(404)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(b"<h1>404 Not Found</h1>")

    def log_message(self, format, *args):
        pass  # Quiet

if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", 3000), JWTHandler)
    print("[+] JWT challenge server on port 3000")
    server.serve_forever()
