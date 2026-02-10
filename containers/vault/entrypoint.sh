#!/bin/bash
# VAULT entrypoint

set -e

# Start SSH (for troubleshooting)
rc-service sshd start

# Start Samba
rc-service samba start

# Start Dovecot (decoy)
rc-service dovecot start 2>/dev/null || true

echo "VAULT container started"
echo "Services: SSH debug (22), Samba (139, 445), IMAP decoy (143)"
echo "Shares: public (guest), backup (guest), classified (auth required)"

# Keep container alive
exec tail -f /dev/null
