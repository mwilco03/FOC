#!/bin/sh
/usr/sbin/sshd
postfix start
nginx
python3 /app/smtp_challenge.py &
dovecot -F
