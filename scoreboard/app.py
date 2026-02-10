#!/usr/bin/env python3
"""
Pivot Lab Scoreboard Backend
Flask API for flag submission, progress tracking, and hint system
"""

import sqlite3
import json
import hashlib
from flask import Flask, request, jsonify
from pathlib import Path

app = Flask(__name__)

# Configuration
STATE_DB = '/var/lib/scoreboard/state.db'
HASH_DB = '/var/lib/scoreboard/hashes.db'
FLAGS_DIR = Path('/flags')

# Hop configuration
HOPS = {
    1: {"container": "GATE", "points": 100, "requires": None},
    2: {"container": "TUNNEL", "points": 150, "requires": 1},
    3: {"container": "FILESERV", "points": 200, "requires": 2},
    4: {"container": "WEBSHELL", "points": 300, "requires": 3},
    5: {"container": "DROPZONE", "points": 400, "requires": 4},
    6: {"container": "DEPOT", "points": 500, "requires": 5},
    7: {"container": "RESOLVER", "points": 600, "requires": 6},
    8: {"container": "CACHE", "points": 800, "requires": 7},
    9: {"container": "VAULT", "points": 1000, "requires": 8},
}

# Hint tiers and costs
HINT_TIERS = [
    {"name": "nudge", "cost_percent": 10, "level": 1},
    {"name": "guide", "cost_percent": 25, "level": 2},
    {"name": "walkthrough", "cost_percent": 50, "level": 3},
]


def init_db():
    """Initialize the state database"""
    conn = sqlite3.connect(STATE_DB)
    c = conn.cursor()

    # Progress table
    c.execute('''CREATE TABLE IF NOT EXISTS progress
                 (hop INTEGER PRIMARY KEY,
                  completed INTEGER DEFAULT 0,
                  timestamp TEXT)''')

    # Hints table
    c.execute('''CREATE TABLE IF NOT EXISTS hints
                 (hop INTEGER PRIMARY KEY,
                  hints_used INTEGER DEFAULT 0,
                  points_deducted INTEGER DEFAULT 0)''')

    # Bonus hint table (one-time free recovery hint after Hop 6)
    c.execute('''CREATE TABLE IF NOT EXISTS bonus_hint
                 (used INTEGER DEFAULT 0,
                  timestamp TEXT)''')

    # Flags table
    c.execute('''CREATE TABLE IF NOT EXISTS flags
                 (hop INTEGER PRIMARY KEY,
                  flag TEXT,
                  submitted INTEGER DEFAULT 0)''')

    conn.commit()
    conn.close()


def load_flags():
    """Load flags from the flags directory"""
    flags = {}
    for hop in range(1, 10):
        flag_file = FLAGS_DIR / f'flag-{hop:02d}.txt'
        if flag_file.exists():
            flags[hop] = flag_file.read_text().strip()
    return flags


def get_db():
    """Get database connection"""
    conn = sqlite3.connect(STATE_DB)
    conn.row_factory = sqlite3.Row
    return conn


@app.route('/api/session', methods=['GET'])
def get_session():
    """Get session information"""
    return jsonify({
        "session_id": "pivot-lab-v5",
        "total_hops": 9,
        "max_points": sum(h["points"] for h in HOPS.values())
    })


@app.route('/api/flags', methods=['POST'])
def submit_flag():
    """Submit a flag (auto-detect which hop)"""
    data = request.get_json()
    submitted_flag = data.get('flag', '').strip()

    if not submitted_flag:
        return jsonify({"valid": False, "message": "No flag provided"}), 400

    # Load current flags
    flags = load_flags()

    # Search for matching flag
    found_hop = None
    for hop, flag in flags.items():
        if submitted_flag == flag:
            found_hop = hop
            break

    if not found_hop:
        return jsonify({"valid": False, "message": "Invalid flag"}), 200

    # Check if already submitted
    conn = get_db()
    c = conn.cursor()
    c.execute('SELECT submitted FROM flags WHERE hop = ?', (found_hop,))
    row = c.fetchone()

    already_submitted = row and row[0] == 1

    if already_submitted:
        # Already submitted, no points awarded
        c.execute('SELECT points_deducted FROM hints WHERE hop = ?', (found_hop,))
        hint_row = c.fetchone()
        hint_deduction = hint_row[0] if hint_row else 0

        total_score = calculate_total_score(conn)
        conn.close()

        return jsonify({
            "valid": True,
            "hop": found_hop,
            "container": HOPS[found_hop]["container"],
            "points_awarded": 0,
            "total_score": total_score,
            "message": "Flag already submitted"
        })

    # Mark as submitted
    import datetime
    timestamp = datetime.datetime.utcnow().isoformat()

    c.execute('''INSERT OR REPLACE INTO flags (hop, flag, submitted)
                 VALUES (?, ?, 1)''', (found_hop, submitted_flag))
    c.execute('''INSERT OR REPLACE INTO progress (hop, completed, timestamp)
                 VALUES (?, 1, ?)''', (found_hop, timestamp))

    conn.commit()

    # Calculate points
    base_points = HOPS[found_hop]["points"]
    c.execute('SELECT points_deducted FROM hints WHERE hop = ?', (found_hop,))
    hint_row = c.fetchone()
    hint_deduction = hint_row[0] if hint_row else 0

    points_awarded = base_points - hint_deduction
    total_score = calculate_total_score(conn)

    conn.close()

    return jsonify({
        "valid": True,
        "hop": found_hop,
        "container": HOPS[found_hop]["container"],
        "points_awarded": points_awarded,
        "total_score": total_score,
        "message": f"{HOPS[found_hop]['container']} compromised"
    })


@app.route('/api/progress', methods=['GET'])
def get_progress():
    """Get current progress"""
    conn = get_db()
    c = conn.cursor()
    c.execute('SELECT hop, completed, timestamp FROM progress WHERE completed = 1')
    rows = c.fetchall()

    completed_hops = {row[0]: {"completed": True, "timestamp": row[2]} for row in rows}

    total_score = calculate_total_score(conn)
    conn.close()

    hops_data = []
    for hop, info in HOPS.items():
        hop_data = {
            "hop": hop,
            "container": info["container"],
            "points": info["points"],
            "completed": hop in completed_hops,
            "timestamp": completed_hops.get(hop, {}).get("timestamp")
        }
        hops_data.append(hop_data)

    return jsonify({
        "total_score": total_score,
        "completed_hops": len(completed_hops),
        "total_hops": 9,
        "hops": hops_data
    })


@app.route('/api/hints/<int:hop>', methods=['GET'])
def get_hints_status(hop):
    """Get hints status for a hop"""
    if hop not in HOPS:
        return jsonify({"error": "Invalid hop"}), 404

    # Check if previous hop is completed (except for Hop 1)
    if hop > 1:
        conn = get_db()
        c = conn.cursor()
        prev_hop = hop - 1
        c.execute('SELECT completed FROM progress WHERE hop = ? AND completed = 1', (prev_hop,))
        if not c.fetchone():
            conn.close()
            return jsonify({
                "available": False,
                "message": f"Complete Hop {prev_hop} to unlock hints for Hop {hop}",
                "requires": f"hop-{prev_hop:02d}"
            })
        conn.close()

    # Get hint usage
    conn = get_db()
    c = conn.cursor()
    c.execute('SELECT hints_used, points_deducted FROM hints WHERE hop = ?', (hop,))
    row = c.fetchone()
    hints_used = row[0] if row else 0
    points_deducted = row[1] if row else 0

    # Check bonus hint availability (after Hop 6)
    c.execute('SELECT completed FROM progress WHERE hop = 6 AND completed = 1')
    hop6_completed = c.fetchone() is not None
    c.execute('SELECT used FROM bonus_hint')
    bonus_row = c.fetchone()
    bonus_used = bonus_row[0] if bonus_row else 0

    conn.close()

    next_hint_cost = 0
    if hints_used < len(HINT_TIERS):
        next_tier = HINT_TIERS[hints_used]
        next_hint_cost = int(HOPS[hop]["points"] * next_tier["cost_percent"] / 100)

    return jsonify({
        "available": True,
        "hints_used": hints_used,
        "hints_total": len(HINT_TIERS),
        "points_deducted": points_deducted,
        "next_hint_cost": next_hint_cost,
        "bonus_hint_available": hop6_completed and not bonus_used,
        "bonus_hint_used": bool(bonus_used)
    })


@app.route('/api/hints', methods=['POST'])
def request_hint():
    """Request a hint for a hop"""
    data = request.get_json()
    hop = data.get('hop')

    if hop not in HOPS:
        return jsonify({"error": "Invalid hop"}), 404

    # Check if hints are available for this hop
    if hop > 1:
        conn = get_db()
        c = conn.cursor()
        prev_hop = hop - 1
        c.execute('SELECT completed FROM progress WHERE hop = ? AND completed = 1', (prev_hop,))
        if not c.fetchone():
            conn.close()
            return jsonify({"error": f"Complete Hop {prev_hop} first"}), 403
        conn.close()

    # Get current hint usage
    conn = get_db()
    c = conn.cursor()
    c.execute('SELECT hints_used, points_deducted FROM hints WHERE hop = ?', (hop,))
    row = c.fetchone()
    hints_used = row[0] if row else 0
    points_deducted = row[1] if row else 0

    if hints_used >= len(HINT_TIERS):
        conn.close()
        return jsonify({"error": "All hints already used"}), 400

    # Calculate cost and update
    tier = HINT_TIERS[hints_used]
    cost = int(HOPS[hop]["points"] * tier["cost_percent"] / 100)
    new_deduction = points_deducted + cost
    new_hints_used = hints_used + 1

    c.execute('''INSERT OR REPLACE INTO hints (hop, hints_used, points_deducted)
                 VALUES (?, ?, ?)''', (hop, new_hints_used, new_deduction))
    conn.commit()
    conn.close()

    # Load hint from hints directory (stub for now)
    hint_text = f"Hint {tier['name']} for Hop {hop}: Check the hints JSON file"

    return jsonify({
        "hint": hint_text,
        "tier": tier["name"],
        "cost": cost,
        "hints_remaining": len(HINT_TIERS) - new_hints_used
    })


@app.route('/api/bonus-hint', methods=['POST'])
def request_bonus_hint():
    """Request the one-time FREE bonus hint (available after Hop 6)"""
    data = request.get_json()
    hop = data.get('hop')

    if hop not in HOPS:
        return jsonify({"error": "Invalid hop"}), 404

    conn = get_db()
    c = conn.cursor()

    # Check if Hop 6 is completed
    c.execute('SELECT completed FROM progress WHERE hop = 6 AND completed = 1')
    if not c.fetchone():
        conn.close()
        return jsonify({"error": "Complete Hop 6 to unlock BONUS HINT"}), 403

    # Check if bonus hint already used
    c.execute('SELECT used FROM bonus_hint')
    row = c.fetchone()
    if row and row[0] == 1:
        conn.close()
        return jsonify({"error": "BONUS HINT already used"}), 400

    # Mark bonus hint as used
    import datetime
    timestamp = datetime.datetime.utcnow().isoformat()
    c.execute('INSERT OR REPLACE INTO bonus_hint (used, timestamp) VALUES (1, ?)', (timestamp,))
    conn.commit()
    conn.close()

    # Return bonus hint (first tier hint, but FREE)
    bonus_text = f"🎁 BONUS HINT (FREE) for Hop {hop}: This is a free recovery hint to help you progress. Check the hints JSON file for Hop {hop} tier 1 (nudge) content."

    return jsonify({
        "hint": bonus_text,
        "tier": "bonus",
        "cost": 0,
        "message": "BONUS HINT activated! No points deducted. This was your one-time free hint."
    })


@app.route('/api/validate-hash', methods=['POST'])
def validate_hash():
    """Validate a cracked hash (Hop 9)"""
    data = request.get_json()
    hash_value = data.get('hash', '').strip()
    plaintext = data.get('plaintext', '').strip()

    if not hash_value or not plaintext:
        return jsonify({"valid": False, "message": "Hash and plaintext required"}), 400

    # Simple validation: hash the plaintext and compare
    # Support MD5, SHA1, SHA256
    algorithms = {
        32: ('MD5', hashlib.md5),
        40: ('SHA1', hashlib.sha1),
        64: ('SHA256', hashlib.sha256),
    }

    hash_len = len(hash_value)
    if hash_len not in algorithms:
        return jsonify({"valid": False, "message": "Unsupported hash format"}), 400

    algo_name, algo_func = algorithms[hash_len]
    computed_hash = algo_func(plaintext.encode()).hexdigest()

    if computed_hash.lower() == hash_value.lower():
        return jsonify({
            "valid": True,
            "algorithm": algo_name,
            "message": "Hash validated successfully"
        })
    else:
        return jsonify({
            "valid": False,
            "message": "Hash does not match plaintext"
        })


@app.route('/api/hash-lookup', methods=['GET'])
def hash_lookup():
    """Fallback hash lookup using local database"""
    hash_value = request.args.get('hash', '').strip()

    if not hash_value:
        return jsonify({"found": False, "message": "No hash provided"}), 400

    # Query local hash database
    try:
        conn = sqlite3.connect(HASH_DB)
        c = conn.cursor()
        c.execute('SELECT algorithm, plaintext FROM hashes WHERE hash = ?', (hash_value.lower(),))
        row = c.fetchone()
        conn.close()

        if row:
            return jsonify({
                "found": True,
                "algorithm": row[0],
                "plaintext": row[1],
                "source": "local"
            })
        else:
            return jsonify({
                "found": False,
                "message": "Hash not found in local database",
                "suggestion": "Try online services: CrackStation, hashes.org"
            })
    except Exception as e:
        return jsonify({"found": False, "message": str(e)}), 500


def calculate_total_score(conn):
    """Calculate total score from completed hops minus hint deductions"""
    c = conn.cursor()
    total = 0

    for hop, info in HOPS.items():
        c.execute('SELECT completed FROM progress WHERE hop = ? AND completed = 1', (hop,))
        if c.fetchone():
            base_points = info["points"]
            c.execute('SELECT points_deducted FROM hints WHERE hop = ?', (hop,))
            hint_row = c.fetchone()
            deduction = hint_row[0] if hint_row else 0
            total += (base_points - deduction)

    return total


if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000)
