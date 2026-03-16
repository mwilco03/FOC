#!/bin/sh
# Block ICMP - students need -Pn to find this host
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP 2>/dev/null
iptables -A OUTPUT -p icmp --icmp-type echo-reply -j DROP 2>/dev/null

# SSH on 22222
/usr/sbin/sshd

# TCP/UDP services
python3 /app/services.py &

sleep infinity
