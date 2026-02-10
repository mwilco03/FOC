#!/bin/bash
# RESOLVER entrypoint

set -e

# Start BIND
rc-service named start

# Start lighttpd (honeypot)
rc-service lighttpd start

echo "RESOLVER container started"
echo "Services: BIND DNS (53), HTTP honeypot (80)"

# Keep container alive
exec tail -f /dev/null
