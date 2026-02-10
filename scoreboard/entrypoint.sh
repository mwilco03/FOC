#!/bin/bash
# Scoreboard entrypoint

set -e

# Initialize database
cd /app
python3 -c "from app import init_db; init_db()"

# Start gunicorn (Flask backend)
gunicorn --bind 127.0.0.1:5000 --workers 4 --daemon app:app

# Start lighttpd (frontend + reverse proxy)
lighttpd -D -f /etc/lighttpd/lighttpd.conf
