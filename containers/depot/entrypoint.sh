#!/bin/bash
# DEPOT entrypoint

set -e

# Start TFTP server
/usr/sbin/in.tftpd -L -s /var/tftpboot -u tftp &

# Start SNMP daemon (decoy)
rc-service snmpd start

echo "DEPOT container started"
echo "Services: TFTP (69/UDP), SNMP decoy (161/UDP)"
echo "TFTP root: /var/tftpboot/"

# Keep container alive
exec tail -f /dev/null
