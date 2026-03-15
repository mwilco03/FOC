#!/bin/bash
# DROPZONE entrypoint

set -e

# Start OpenSSH
rc-service sshd start

# Start vsftpd (locked down decoy)
/usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf &

# lighttpd is deliberately NOT started - stopped service pattern
# Player must discover and start it with: sudo rc-service lighttpd start

echo "DROPZONE container started"
echo "Services: SSH (22), FTP locked (21)"
echo "Stopped services: lighttpd + WebDAV (installed but not started)"

# Keep container alive
exec tail -f /dev/null
