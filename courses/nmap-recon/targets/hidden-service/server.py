#!/usr/bin/env python3
"""Hidden service with high ports and UDP for advanced nmap training."""

import socket
import threading
import time

def serve_tcp_31337():
    """Elite port - instant response."""
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind(("0.0.0.0", 31337))
    sock.listen(5)
    print("[+] Elite service on TCP 31337")
    while True:
        conn, addr = sock.accept()
        try:
            conn.sendall(b"31337 Elite Service\r\nFLAG{elite_port_31337}\r\n")
            conn.settimeout(3)
            try:
                conn.recv(1024)
            except socket.timeout:
                pass
        except (BrokenPipeError, ConnectionResetError):
            pass
        finally:
            conn.close()


def serve_tcp_65000():
    """Slow-responding service - tests patience with scan timing."""
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind(("0.0.0.0", 65000))
    sock.listen(5)
    print("[+] Slow service on TCP 65000")
    while True:
        conn, addr = sock.accept()
        try:
            # Delay before sending banner to test scan timing
            time.sleep(3)
            conn.sendall(b"Slow Response Service v1.0\r\nFLAG{patience_rewarded_65000}\r\n")
            conn.settimeout(3)
            try:
                conn.recv(1024)
            except socket.timeout:
                pass
        except (BrokenPipeError, ConnectionResetError):
            pass
        finally:
            conn.close()


def serve_udp_4444():
    """UDP service - requires -sU scan to discover."""
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(("0.0.0.0", 4444))
    print("[+] UDP service on port 4444")
    while True:
        data, addr = sock.recvfrom(1024)
        response = b"UDP Hidden Service\r\nFLAG{udp_service_discovered}\r\n"
        sock.sendto(response, addr)


if __name__ == "__main__":
    threads = [
        threading.Thread(target=serve_tcp_31337, daemon=True),
        threading.Thread(target=serve_tcp_65000, daemon=True),
        threading.Thread(target=serve_udp_4444, daemon=True),
    ]
    for t in threads:
        t.start()

    print("[*] Hidden service started (TCP 31337, TCP 65000, UDP 4444)")

    while True:
        time.sleep(3600)
