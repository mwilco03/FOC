#!/bin/bash
# RESOLVER entrypoint

set -e

# Start SSH (for troubleshooting)
rc-service sshd start

# Start BIND
rc-service named start

# Start lighttpd (honeypot)
rc-service lighttpd start

echo "RESOLVER container started"
echo "Services: SSH debug (22), BIND DNS (53), HTTP honeypot (80)"

# Keep container alive
exec tail -f /dev/null
