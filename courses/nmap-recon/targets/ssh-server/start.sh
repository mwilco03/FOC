#!/bin/sh
# Block ICMP to simulate hardened host (best-effort — requires NET_ADMIN)
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP 2>/dev/null || true
iptables -A OUTPUT -p icmp --icmp-type echo-reply -j DROP 2>/dev/null || true

# sshd as PID 1 — keeps container alive
exec /usr/sbin/sshd -D -e
