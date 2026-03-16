#!/usr/bin/env python3
"""Multi-port custom application server for nmap training."""

import socket
import threading

SERVICES = {
    4444: {
        "banner": "Custom Admin Panel v2.1\r\nFLAG{custom_app_admin_panel}\r\n",
        "name": "admin-panel",
    },
    5555: {
        "banner": "Internal Monitoring Agent v1.0\r\nFLAG{monitoring_agent_found}\r\n",
        "name": "monitor",
    },
    6666: {
        "banner": "Debug Console - Unauthorized Access Prohibited\r\nFLAG{debug_console_exposed}\r\n",
        "name": "debug",
    },
    9999: {
        "banner": "Backup Service v3.2\r\nFLAG{backup_service_9999}\r\n",
        "name": "backup",
    },
}


def handle_client(conn, addr, port_config):
    try:
        conn.sendall(port_config["banner"].encode())
        # Wait briefly for any input then close
        conn.settimeout(5)
        try:
            conn.recv(1024)
        except socket.timeout:
            pass
    except (BrokenPipeError, ConnectionResetError):
        pass
    finally:
        conn.close()


def serve_port(port, config):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind(("0.0.0.0", port))
    sock.listen(5)
    print(f"[+] {config['name']} listening on port {port}")
    while True:
        conn, addr = sock.accept()
        t = threading.Thread(target=handle_client, args=(conn, addr, config))
        t.daemon = True
        t.start()


if __name__ == "__main__":
    for port, config in SERVICES.items():
        t = threading.Thread(target=serve_port, args=(port, config))
        t.daemon = True
        t.start()

    print("[*] Custom application server started on ports:", list(SERVICES.keys()))

    # Keep main thread alive
    import time
    while True:
        time.sleep(3600)
