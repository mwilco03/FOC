#!/bin/sh
/usr/sbin/sshd
mysqld_safe --skip-grant-tables &
python3 /app/jwt_server.py &
sleep 1
nginx -g 'daemon off;'
