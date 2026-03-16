#!/bin/bash
/usr/sbin/sshd
python3 /app/dns_server.py &
python3 /app/services.py &
sleep infinity
