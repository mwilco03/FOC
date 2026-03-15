#!/bin/bash
# FILESERV entrypoint

set -e

# Start MariaDB (decoy)
rc-service mariadb start

# Start vsftpd
/usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf &

echo "FILESERV container started"
echo "Services: FTP anonymous (21), MySQL decoy (3306)"

# Keep container alive
exec tail -f /dev/null
