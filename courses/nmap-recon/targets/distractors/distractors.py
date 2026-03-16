#!/usr/bin/env python3
"""Distractor services - look interesting but contain no flags.
Each instance uses ROLE env var to determine personality."""

import os
import socket
import threading
import time

ROLE = os.environ.get("ROLE", "printer")

ROLES = {
    "printer": {
        80: "HP LaserJet Pro MFP M428fdw\r\nReady\r\n",
        443: "HP Web Interface\r\nSSL Required\r\n",
        9100: "PCL Printer\r\n",
        515: "",  # LPD - silent
    },
    "camera": {
        80: "Axis P3245-V Network Camera\r\nAuthentication Required\r\n",
        443: "RTSP over HTTPS\r\n",
        554: "RTSP/1.0 200 OK\r\n",
    },
    "monitoring": {
        80: "Nagios XI\r\nLogin Required\r\n",
        443: "Grafana v10.2.1\r\nRedirecting to /login...\r\n",
        8080: "Prometheus\r\nMetrics endpoint: /metrics\r\n",
        9090: "Alertmanager v0.26\r\n",
    },
    "iot": {
        80: "Smart Building Controller v3.1\r\nHVAC System Online\r\n",
        443: "",
        1883: "MQTT Broker\r\n",
        8883: "",
    },
    "testserver": {
        22: "SSH-2.0-OpenSSH_8.9p1 Ubuntu-3ubuntu0.6\r\n",
        80: "Apache/2.4.52 (Ubuntu)\r\nIt works!\r\n",
        3000: "Gitea Version: 1.21.4\r\n",
        8080: "Jenkins v2.426.3\r\nAuthentication required\r\n",
    },
    "vpn": {
        443: "OpenVPN Access Server\r\n",
        943: "OpenVPN Admin UI\r\nLogin Required\r\n",
        1194: "",
    },
    "voip": {
        80: "FreePBX Administration\r\n",
        5060: "SIP/2.0 200 OK\r\n",
        5061: "",
        8088: "Asterisk REST Interface\r\n",
    },
}

def handle(conn, banner):
    try:
        if banner:
            conn.sendall(banner.encode())
        conn.settimeout(3)
        try: conn.recv(1024)
        except: pass
    except: pass
    finally: conn.close()

def serve(port, banner):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind(("0.0.0.0", port))
        s.listen(5)
        print(f"[+] {ROLE} port {port}")
        while True:
            c, _ = s.accept()
            threading.Thread(target=handle, args=(c, banner), daemon=True).start()
    except Exception as e:
        print(f"[-] {ROLE} port {port}: {e}")

if __name__ == "__main__":
    services = ROLES.get(ROLE, ROLES["printer"])
    print(f"[*] Distractor: {ROLE} ({len(services)} ports)")
    for port, banner in services.items():
        threading.Thread(target=serve, args=(port, banner), daemon=True).start()
    while True: time.sleep(3600)
