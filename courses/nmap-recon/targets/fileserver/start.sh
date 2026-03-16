#!/bin/sh
/usr/sbin/sshd
smbd -D
nmbd -D
python3 /app/ftp_server.py &
sleep infinity
