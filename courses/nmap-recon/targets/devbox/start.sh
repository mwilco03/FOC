#!/bin/bash
/usr/sbin/sshd
dnsmasq
python3 /app/services.py &
sleep infinity
