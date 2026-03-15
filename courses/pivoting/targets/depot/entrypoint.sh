#!/bin/bash
# DEPOT entrypoint

set -e

# Start SSH (for troubleshooting)
rc-service sshd start

# Start TFTP server
/usr/sbin/in.tftpd -L -s /var/tftpboot -u tftp &

# Start SNMP daemon (decoy)
rc-service snmpd start

echo "DEPOT container started"
echo "Services: SSH debug (22), TFTP (69/UDP), SNMP decoy (161/UDP)"
echo "TFTP root: /var/tftpboot/"

# Keep container alive
exec tail -f /dev/null
