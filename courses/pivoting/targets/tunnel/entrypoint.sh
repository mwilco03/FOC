#!/bin/bash
# TUNNEL entrypoint

set -e

# Start OpenSSH
rc-service sshd start

# Start lighttpd (decoy)
rc-service lighttpd start

echo "TUNNEL container started"
echo "Services: SSH (22), HTTP decoy (80)"

# Keep container alive
exec tail -f /dev/null
