#!/bin/bash
# GATE entrypoint

set -e

# Start OpenSSH
rc-service sshd start

# Start Postfix (decoy)
rc-service postfix start

# Start ncat listener on port 9999 (primary challenge)
ncat -l -p 9999 -k -c /usr/local/bin/ncat-banner.sh &

echo "GATE container started"
echo "Services: SSH (22), SMTP decoy (25), ncat (9999)"

# Keep container alive
exec tail -f /dev/null
