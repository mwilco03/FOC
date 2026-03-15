#!/bin/bash
# WEBSHELL entrypoint

set -e

# Start dnsmasq (decoy)
rc-service dnsmasq start

# Start lighttpd with PHP
rc-service lighttpd start

echo "WEBSHELL container started"
echo "Services: HTTP+PHP (80), DNS decoy (53/UDP)"
echo "PRIVESC: SUID find binary present"

# Keep container alive
exec tail -f /dev/null
