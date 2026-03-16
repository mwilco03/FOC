#!/usr/bin/env python3
"""Hardened host - unusual ports, slow responses, UDP, port knocking."""

import socket
import threading
import time
from collections import defaultdict

# Track knock sequences per source IP
knock_state = defaultdict(list)
knock_lock = threading.Lock()
KNOCK_SEQUENCE = [7000, 8000, 9000]
KNOCK_WINDOW = 15      # seconds to complete sequence
OPEN_DURATION = 30     # seconds port stays open after correct knock
open_ips = {}          # ip -> expiry timestamp


def serve_tcp(port, banner, delay=0):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(("0.0.0.0", port))
    s.listen(5)
    print(f"[+] TCP {port}")
    while True:
        c, addr = s.accept()
        def handle(conn, b, d):
            try:
                if d: time.sleep(d)
                conn.sendall(b.encode())
                conn.settimeout(3)
                try: conn.recv(1024)
                except: pass
            except: pass
            finally: conn.close()
        threading.Thread(target=handle, args=(c, banner, delay), daemon=True).start()


def serve_udp(port, banner):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.bind(("0.0.0.0", port))
    print(f"[+] UDP {port}")
    while True:
        data, addr = s.recvfrom(1024)
        s.sendto(banner.encode(), addr)


def knock_listener(port):
    """Listen for knock attempts on a port. Close immediately but record the knock."""
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(("0.0.0.0", port))
    s.listen(5)
    print(f"[+] Knock listener on {port}")
    while True:
        c, addr = s.accept()
        ip = addr[0]
        c.close()  # Immediately close - it's just a knock

        with knock_lock:
            now = time.time()
            # Record this knock
            knock_state[ip].append((port, now))
            # Clean old knocks
            knock_state[ip] = [(p, t) for p, t in knock_state[ip] if now - t < KNOCK_WINDOW]
            # Check sequence
            ports_knocked = [p for p, t in knock_state[ip]]
            if ports_knocked[-len(KNOCK_SEQUENCE):] == KNOCK_SEQUENCE:
                open_ips[ip] = now + OPEN_DURATION
                knock_state[ip] = []
                print(f"[!] Port knock SUCCESS from {ip} - port 1337 open for {OPEN_DURATION}s")


def knock_reward_server():
    """Port 1337 - only responds if the source IP has completed the knock sequence."""
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(("0.0.0.0", 1337))
    s.listen(5)
    print("[+] Knock reward on port 1337 (locked until knock sequence)")
    while True:
        c, addr = s.accept()
        ip = addr[0]
        now = time.time()
        if ip in open_ips and open_ips[ip] > now:
            remaining = int(open_ips[ip] - now)
            c.sendall(f"Door opened! ({remaining}s remaining)\r\nFLAG{{port_knock_master}}\r\n".encode())
        else:
            c.sendall(b"Locked. Knock knock...\r\nHint: try connecting to ports 7000, 8000, 9000 in sequence.\r\n")
        try:
            c.settimeout(2)
            c.recv(1024)
        except: pass
        c.close()


if __name__ == "__main__":
    # Port 2 - outside nmap default top 1000
    threading.Thread(target=serve_tcp, args=(2, "FLAG{port2_not_in_top1000}\r\n"), daemon=True).start()
    # Port 31337 - elite
    threading.Thread(target=serve_tcp, args=(31337, "31337 Elite Service\r\nFLAG{elite_port_31337}\r\n"), daemon=True).start()
    # Port 65000 - slow responder
    threading.Thread(target=serve_tcp, args=(65000, "Slow Response Service\r\nFLAG{patience_rewarded_65000}\r\n", 3), daemon=True).start()
    # UDP 4444
    threading.Thread(target=serve_udp, args=(4444, "FLAG{udp_service_discovered}\r\n"), daemon=True).start()
    # Port knock listeners
    for p in KNOCK_SEQUENCE:
        threading.Thread(target=knock_listener, args=(p,), daemon=True).start()
    # Port knock reward
    threading.Thread(target=knock_reward_server, daemon=True).start()

    print("[*] Hardened host services started (including port knock on 7000→8000→9000→1337)")
    while True: time.sleep(3600)
