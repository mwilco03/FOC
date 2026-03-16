#!/usr/bin/env python3
"""Developer workstation multi-port services."""

import socket
import threading
import time

SERVICES = {
    4444: ("Admin Panel v2.1\r\nFLAG{custom_app_admin_panel}\r\n", "admin-panel"),
    5555: ("Internal Monitoring Agent v1.0\r\nFLAG{monitoring_agent_found}\r\n", "monitor"),
    6666: ("Debug Console - Unauthorized Access Prohibited\r\nFLAG{debug_console_exposed}\r\n", "debug"),
    9999: ("Backup Service v3.2\r\nFLAG{backup_service_9999}\r\n", "backup"),
}

def handle(conn, banner):
    try:
        conn.sendall(banner.encode())
        conn.settimeout(5)
        try: conn.recv(1024)
        except: pass
    except: pass
    finally: conn.close()

def serve(port, banner, name):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(("0.0.0.0", port))
    s.listen(5)
    print(f"[+] {name} on port {port}")
    while True:
        c, _ = s.accept()
        threading.Thread(target=handle, args=(c, banner), daemon=True).start()

if __name__ == "__main__":
    for port, (banner, name) in SERVICES.items():
        threading.Thread(target=serve, args=(port, banner, name), daemon=True).start()
    print("[*] Dev services started")
    while True: time.sleep(3600)
