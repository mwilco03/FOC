#!/usr/bin/env python3
"""
Generate a synthetic attack PCAP for the threat hunt lab.
Produces traffic matching the kill chain timeline:
  - Normal web browsing noise (HTTP + TLS)
  - DNS C2 beaconing (30s intervals to update-service.xyz)
  - SMB lateral movement with negotiate/session/tree (VLAN 20 -> VLAN 30)
  - DNS tunneling exfiltration (base64 in subdomain labels)
  - Discovery scan (SYN sweep of internal range)

Requires: pip install scapy
Usage: python3 generate_pcap.py [output.pcap]
"""

import sys
import base64
import random
import struct
from datetime import datetime, timedelta

try:
    from scapy.all import (
        IP, TCP, UDP, DNS, DNSQR, DNSRR, Ether, Raw,
        wrpcap, conf
    )
except ImportError:
    print("Install scapy: pip install scapy")
    sys.exit(1)

conf.verb = 0  # silence scapy

OUTPUT = sys.argv[1] if len(sys.argv) > 1 else "attack.pcap"

# --- Network topology ---
VICTIM_IP = "172.20.1.50"        # Compromised kiosk (VLAN 20)
VICTIM_MAC = "00:15:5d:01:04:01"
GW_IP = "172.20.1.1"             # Gateway
GW_MAC = "00:15:5d:00:00:01"
DNS_SERVER = "8.8.8.8"
C2_DOMAIN = "update-service.xyz"
C2_IP = "203.0.113.99"           # External C2 server
RELIEF_IP = "10.10.30.5"         # Relief ops file server (VLAN 30)
RELIEF_MAC = "00:15:5d:02:05:01"
INTERNAL_RANGE = "10.10.30"      # Scan target range

# --- Timing ---
BASE_TIME = datetime(2026, 3, 14, 14, 23, 0)  # Attack start
packets = []
tcp_seq = {}  # Track sequence numbers per flow


def ts(offset_seconds):
    """Return epoch timestamp at offset from base."""
    return (BASE_TIME + timedelta(seconds=offset_seconds)).timestamp()


def add_pkt(pkt, offset_seconds):
    """Add packet with timestamp."""
    pkt.time = ts(offset_seconds)
    packets.append(pkt)


def tcp_handshake(src_ip, dst_ip, src_mac, dst_mac, sport, dport, t_offset, ttl=64):
    """Full TCP 3-way handshake. Returns (seq, ack) for continued use."""
    seq0 = random.randint(1000000, 9999999)
    ack0 = random.randint(1000000, 9999999)
    # SYN
    add_pkt(Ether(src=src_mac, dst=dst_mac) /
            IP(src=src_ip, dst=dst_ip, ttl=ttl) /
            TCP(sport=sport, dport=dport, flags="S", seq=seq0), t_offset)
    # SYN-ACK
    add_pkt(Ether(src=dst_mac, dst=src_mac) /
            IP(src=dst_ip, dst=src_ip, ttl=ttl) /
            TCP(sport=dport, dport=sport, flags="SA", seq=ack0, ack=seq0 + 1), t_offset + 0.02)
    # ACK
    add_pkt(Ether(src=src_mac, dst=dst_mac) /
            IP(src=src_ip, dst=dst_ip, ttl=ttl) /
            TCP(sport=sport, dport=dport, flags="A", seq=seq0 + 1, ack=ack0 + 1), t_offset + 0.04)
    return seq0 + 1, ack0 + 1


def tcp_data(src_ip, dst_ip, src_mac, dst_mac, sport, dport, seq, ack, data, t_offset, ttl=64):
    """Send TCP data and get ACK back. Returns updated (seq, ack)."""
    add_pkt(Ether(src=src_mac, dst=dst_mac) /
            IP(src=src_ip, dst=dst_ip, ttl=ttl) /
            TCP(sport=sport, dport=dport, flags="PA", seq=seq, ack=ack) /
            Raw(load=data), t_offset)
    new_seq = seq + len(data)
    # ACK from receiver
    add_pkt(Ether(src=dst_mac, dst=src_mac) /
            IP(src=dst_ip, dst=src_ip, ttl=ttl) /
            TCP(sport=dport, dport=sport, flags="A", seq=ack, ack=new_seq), t_offset + 0.02)
    return new_seq, ack


def tcp_fin(src_ip, dst_ip, src_mac, dst_mac, sport, dport, seq, ack, t_offset, ttl=64):
    """Graceful TCP close."""
    add_pkt(Ether(src=src_mac, dst=dst_mac) /
            IP(src=src_ip, dst=dst_ip, ttl=ttl) /
            TCP(sport=sport, dport=dport, flags="FA", seq=seq, ack=ack), t_offset)
    add_pkt(Ether(src=dst_mac, dst=src_mac) /
            IP(src=dst_ip, dst=src_ip, ttl=ttl) /
            TCP(sport=dport, dport=sport, flags="FA", seq=ack, ack=seq + 1), t_offset + 0.02)
    add_pkt(Ether(src=src_mac, dst=dst_mac) /
            IP(src=src_ip, dst=dst_ip, ttl=ttl) /
            TCP(sport=sport, dport=dport, flags="A", seq=seq + 1, ack=ack + 1), t_offset + 0.04)


# ---------------------------------------------------------------------------
# SMB protocol helpers (minimal but enough for Zeek to parse)
# ---------------------------------------------------------------------------
def smb2_negotiate_request():
    """SMB2 Negotiate Protocol Request."""
    # NetBIOS session header + SMB2 header + Negotiate request
    smb2_header = b'\xfeSMB'  # SMB2 magic
    smb2_header += struct.pack('<H', 64)  # header length
    smb2_header += struct.pack('<H', 0)   # credit charge
    smb2_header += struct.pack('<I', 0)   # status
    smb2_header += struct.pack('<H', 0)   # command: NEGOTIATE
    smb2_header += struct.pack('<H', 1)   # credits requested
    smb2_header += struct.pack('<I', 0)   # flags
    smb2_header += struct.pack('<I', 0)   # next command
    smb2_header += struct.pack('<Q', 1)   # message id
    smb2_header += struct.pack('<I', 0)   # reserved
    smb2_header += struct.pack('<I', 0)   # tree id
    smb2_header += struct.pack('<Q', 0)   # session id
    smb2_header += b'\x00' * 16          # signature

    # Negotiate body
    neg_body = struct.pack('<H', 36)   # structure size
    neg_body += struct.pack('<H', 2)   # dialect count
    neg_body += struct.pack('<H', 0)   # security mode
    neg_body += struct.pack('<H', 0)   # reserved
    neg_body += struct.pack('<I', 0x7f)  # capabilities
    neg_body += b'\x00' * 16           # client guid
    neg_body += struct.pack('<I', 0)   # negotiate context offset
    neg_body += struct.pack('<H', 0)   # negotiate context count
    neg_body += struct.pack('<H', 0)   # reserved2
    neg_body += struct.pack('<H', 0x0202)  # dialect SMB 2.0.2
    neg_body += struct.pack('<H', 0x0210)  # dialect SMB 2.1

    msg = smb2_header + neg_body
    # NetBIOS header
    nb = b'\x00' + struct.pack('>I', len(msg))[1:]
    return nb + msg


def smb2_negotiate_response():
    """SMB2 Negotiate Protocol Response."""
    smb2_header = b'\xfeSMB'
    smb2_header += struct.pack('<H', 64)
    smb2_header += struct.pack('<H', 0)
    smb2_header += struct.pack('<I', 0)   # STATUS_SUCCESS
    smb2_header += struct.pack('<H', 0)   # command: NEGOTIATE
    smb2_header += struct.pack('<H', 1)
    smb2_header += struct.pack('<I', 1)   # flags: response
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<Q', 1)
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<Q', 0)
    smb2_header += b'\x00' * 16

    # Response body
    resp = struct.pack('<H', 65)   # structure size
    resp += struct.pack('<H', 1)   # security mode: signing enabled
    resp += struct.pack('<H', 0x0210)  # dialect: SMB 2.1
    resp += struct.pack('<H', 0)   # reserved
    resp += b'\x00' * 16          # server guid
    resp += struct.pack('<I', 0x7f)  # capabilities
    resp += struct.pack('<I', 1048576)  # max transact size
    resp += struct.pack('<I', 1048576)  # max read size
    resp += struct.pack('<I', 1048576)  # max write size
    resp += struct.pack('<Q', 0)   # system time
    resp += struct.pack('<Q', 0)   # server start time
    resp += struct.pack('<H', 128)  # security buffer offset
    resp += struct.pack('<H', 0)   # security buffer length
    resp += struct.pack('<I', 0)   # reserved2

    msg = smb2_header + resp
    nb = b'\x00' + struct.pack('>I', len(msg))[1:]
    return nb + msg


def smb2_session_setup_request():
    """SMB2 Session Setup Request."""
    smb2_header = b'\xfeSMB'
    smb2_header += struct.pack('<H', 64)
    smb2_header += struct.pack('<H', 0)
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<H', 1)   # command: SESSION_SETUP
    smb2_header += struct.pack('<H', 1)
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<Q', 2)   # message id
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<Q', 0)
    smb2_header += b'\x00' * 16

    body = struct.pack('<H', 25)   # structure size
    body += struct.pack('<B', 0)   # flags
    body += struct.pack('<B', 1)   # security mode
    body += struct.pack('<I', 0)   # capabilities
    body += struct.pack('<I', 0)   # channel
    body += struct.pack('<H', 88)  # security buffer offset
    body += struct.pack('<H', 16)  # security buffer length
    body += struct.pack('<Q', 0)   # previous session id
    # NTLMSSP negotiate token (minimal)
    body += b'NTLMSSP\x00' + struct.pack('<I', 1) + struct.pack('<I', 0)

    msg = smb2_header + body
    nb = b'\x00' + struct.pack('>I', len(msg))[1:]
    return nb + msg


def smb2_session_setup_response():
    """SMB2 Session Setup Response (success)."""
    smb2_header = b'\xfeSMB'
    smb2_header += struct.pack('<H', 64)
    smb2_header += struct.pack('<H', 0)
    smb2_header += struct.pack('<I', 0)   # STATUS_SUCCESS
    smb2_header += struct.pack('<H', 1)   # SESSION_SETUP
    smb2_header += struct.pack('<H', 1)
    smb2_header += struct.pack('<I', 1)   # response flag
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<Q', 2)
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<Q', 0x10000000001)  # session id
    smb2_header += b'\x00' * 16

    body = struct.pack('<H', 9)
    body += struct.pack('<H', 0)   # session flags
    body += struct.pack('<H', 72)  # security buffer offset
    body += struct.pack('<H', 0)   # security buffer length

    msg = smb2_header + body
    nb = b'\x00' + struct.pack('>I', len(msg))[1:]
    return nb + msg


def smb2_tree_connect_request(share_name="\\\\10.10.30.5\\share"):
    """SMB2 Tree Connect Request."""
    smb2_header = b'\xfeSMB'
    smb2_header += struct.pack('<H', 64)
    smb2_header += struct.pack('<H', 0)
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<H', 3)   # command: TREE_CONNECT
    smb2_header += struct.pack('<H', 1)
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<Q', 3)   # message id
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<Q', 0x10000000001)  # session id
    smb2_header += b'\x00' * 16

    share_bytes = share_name.encode('utf-16-le')
    body = struct.pack('<H', 9)    # structure size
    body += struct.pack('<H', 0)   # reserved
    body += struct.pack('<H', 72)  # path offset
    body += struct.pack('<H', len(share_bytes))  # path length
    body += share_bytes

    msg = smb2_header + body
    nb = b'\x00' + struct.pack('>I', len(msg))[1:]
    return nb + msg


def smb2_tree_connect_response():
    """SMB2 Tree Connect Response."""
    smb2_header = b'\xfeSMB'
    smb2_header += struct.pack('<H', 64)
    smb2_header += struct.pack('<H', 0)
    smb2_header += struct.pack('<I', 0)   # STATUS_SUCCESS
    smb2_header += struct.pack('<H', 3)   # TREE_CONNECT
    smb2_header += struct.pack('<H', 1)
    smb2_header += struct.pack('<I', 1)   # response
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<Q', 3)
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<I', 1)   # tree id
    smb2_header += struct.pack('<Q', 0x10000000001)
    smb2_header += b'\x00' * 16

    body = struct.pack('<H', 16)   # structure size
    body += struct.pack('<B', 1)   # share type: disk
    body += struct.pack('<B', 0)   # reserved
    body += struct.pack('<I', 0x100081)  # share flags
    body += struct.pack('<I', 0x1f01ff)  # capabilities
    body += struct.pack('<I', 0x1f01ff)  # maximal access

    msg = smb2_header + body
    nb = b'\x00' + struct.pack('>I', len(msg))[1:]
    return nb + msg


def smb2_create_request(filename="relief-ops.xlsx"):
    """SMB2 Create (open file) Request."""
    smb2_header = b'\xfeSMB'
    smb2_header += struct.pack('<H', 64)
    smb2_header += struct.pack('<H', 0)
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<H', 5)   # command: CREATE
    smb2_header += struct.pack('<H', 1)
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<Q', 4)
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<I', 1)   # tree id
    smb2_header += struct.pack('<Q', 0x10000000001)
    smb2_header += b'\x00' * 16

    fname_bytes = filename.encode('utf-16-le')
    body = struct.pack('<H', 57)   # structure size
    body += struct.pack('<B', 0)   # oplock level
    body += struct.pack('<I', 0)   # impersonation level
    body += struct.pack('<Q', 0)   # smb create flags
    body += struct.pack('<Q', 0)   # reserved
    body += struct.pack('<I', 0x80)  # desired access: read
    body += struct.pack('<I', 0x7)   # file attributes
    body += struct.pack('<I', 0x3)   # share access: read|write
    body += struct.pack('<I', 1)     # create disposition: open
    body += struct.pack('<I', 0)     # create options
    body += struct.pack('<H', 120)   # name offset
    body += struct.pack('<H', len(fname_bytes))  # name length
    body += struct.pack('<I', 0)     # context offset
    body += struct.pack('<I', 0)     # context length
    body += fname_bytes

    msg = smb2_header + body
    nb = b'\x00' + struct.pack('>I', len(msg))[1:]
    return nb + msg


def smb2_create_response():
    """SMB2 Create Response (file opened)."""
    smb2_header = b'\xfeSMB'
    smb2_header += struct.pack('<H', 64)
    smb2_header += struct.pack('<H', 0)
    smb2_header += struct.pack('<I', 0)   # STATUS_SUCCESS
    smb2_header += struct.pack('<H', 5)   # CREATE
    smb2_header += struct.pack('<H', 1)
    smb2_header += struct.pack('<I', 1)
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<Q', 4)
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<I', 1)
    smb2_header += struct.pack('<Q', 0x10000000001)
    smb2_header += b'\x00' * 16

    body = struct.pack('<H', 89)   # structure size
    body += struct.pack('<B', 0)   # oplock level
    body += struct.pack('<I', 1)   # create action: opened
    body += struct.pack('<Q', 0)   # creation time
    body += struct.pack('<Q', 0)   # last access time
    body += struct.pack('<Q', 0)   # last write time
    body += struct.pack('<Q', 0)   # change time
    body += struct.pack('<Q', 28672)  # allocation size
    body += struct.pack('<Q', 25600)  # end of file (file size)
    body += struct.pack('<I', 0x20)  # file attributes: archive
    body += struct.pack('<I', 0)     # reserved
    body += struct.pack('<Q', 0xFFFFFFFF00000001)  # file id persistent
    body += struct.pack('<Q', 0x01)  # file id volatile
    body += struct.pack('<I', 0)     # context offset
    body += struct.pack('<I', 0)     # context length

    msg = smb2_header + body
    nb = b'\x00' + struct.pack('>I', len(msg))[1:]
    return nb + msg


def smb2_read_request():
    """SMB2 Read Request."""
    smb2_header = b'\xfeSMB'
    smb2_header += struct.pack('<H', 64)
    smb2_header += struct.pack('<H', 0)
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<H', 8)   # command: READ
    smb2_header += struct.pack('<H', 1)
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<Q', 5)
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<I', 1)
    smb2_header += struct.pack('<Q', 0x10000000001)
    smb2_header += b'\x00' * 16

    body = struct.pack('<H', 49)         # structure size
    body += struct.pack('<B', 0)         # padding
    body += struct.pack('<B', 0)         # flags
    body += struct.pack('<I', 65536)     # read length
    body += struct.pack('<Q', 0)         # offset
    body += struct.pack('<Q', 0xFFFFFFFF00000001)  # file id persistent
    body += struct.pack('<Q', 0x01)      # file id volatile
    body += struct.pack('<I', 0)         # minimum count
    body += struct.pack('<I', 0)         # channel
    body += struct.pack('<I', 0)         # remaining bytes
    body += struct.pack('<H', 0)         # read channel info offset
    body += struct.pack('<H', 0)         # read channel info length

    msg = smb2_header + body
    nb = b'\x00' + struct.pack('>I', len(msg))[1:]
    return nb + msg


def smb2_read_response(data_len=25600):
    """SMB2 Read Response with simulated file data."""
    smb2_header = b'\xfeSMB'
    smb2_header += struct.pack('<H', 64)
    smb2_header += struct.pack('<H', 0)
    smb2_header += struct.pack('<I', 0)   # STATUS_SUCCESS
    smb2_header += struct.pack('<H', 8)   # READ
    smb2_header += struct.pack('<H', 1)
    smb2_header += struct.pack('<I', 1)
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<Q', 5)
    smb2_header += struct.pack('<I', 0)
    smb2_header += struct.pack('<I', 1)
    smb2_header += struct.pack('<Q', 0x10000000001)
    smb2_header += b'\x00' * 16

    body = struct.pack('<H', 17)         # structure size
    body += struct.pack('<B', 80)        # data offset
    body += struct.pack('<B', 0)         # reserved
    body += struct.pack('<I', data_len)  # data length
    body += struct.pack('<I', 0)         # data remaining
    body += struct.pack('<I', 0)         # reserved2
    # Simulated xlsx header (PK zip magic)
    body += b'PK\x03\x04' + b'\x00' * (min(data_len, 1400) - 4)

    msg = smb2_header + body
    nb = b'\x00' + struct.pack('>I', len(msg))[1:]
    return nb + msg


# ---------------------------------------------------------------------------
# TLS Client Hello helper (enough for Zeek to log ssl.log)
# ---------------------------------------------------------------------------
def tls_client_hello(server_name="www.google.com"):
    """Minimal TLS 1.2 Client Hello with SNI extension."""
    # SNI extension
    host_bytes = server_name.encode()
    sni_entry = struct.pack('>B', 0) + struct.pack('>H', len(host_bytes)) + host_bytes
    sni_list = struct.pack('>H', len(sni_entry)) + sni_entry
    sni_ext = struct.pack('>H', 0) + struct.pack('>H', len(sni_list)) + sni_list  # type=0x0000 (SNI)

    # Supported versions extension (TLS 1.2)
    ver_ext = struct.pack('>H', 0x002b) + struct.pack('>H', 3) + struct.pack('>B', 2) + struct.pack('>H', 0x0303)

    extensions = sni_ext + ver_ext
    extensions_block = struct.pack('>H', len(extensions)) + extensions

    # Client Hello body
    ch = struct.pack('>H', 0x0303)  # client version TLS 1.2
    ch += b'\x00' * 32             # random
    ch += struct.pack('>B', 0)     # session id length
    ch += struct.pack('>H', 4)    # cipher suites length
    ch += struct.pack('>H', 0xc02f)  # TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
    ch += struct.pack('>H', 0x009e)  # TLS_DHE_RSA_WITH_AES_128_GCM_SHA256
    ch += struct.pack('>B', 1)     # compression methods length
    ch += struct.pack('>B', 0)     # null compression
    ch += extensions_block

    # Handshake header
    hs = struct.pack('>B', 1)  # handshake type: Client Hello
    hs += struct.pack('>I', len(ch))[1:]  # 3-byte length
    hs += ch

    # TLS record
    record = struct.pack('>B', 22)      # content type: handshake
    record += struct.pack('>H', 0x0301)  # TLS 1.0 for record layer
    record += struct.pack('>H', len(hs))
    record += hs

    return record


def tls_server_hello():
    """Minimal TLS Server Hello."""
    sh = struct.pack('>H', 0x0303)  # TLS 1.2
    sh += b'\x00' * 32             # random
    sh += struct.pack('>B', 32)    # session id length
    sh += b'\x01' * 32            # session id
    sh += struct.pack('>H', 0xc02f)  # cipher suite
    sh += struct.pack('>B', 0)     # compression

    hs = struct.pack('>B', 2)  # Server Hello
    hs += struct.pack('>I', len(sh))[1:]
    hs += sh

    record = struct.pack('>B', 22)
    record += struct.pack('>H', 0x0303)
    record += struct.pack('>H', len(hs))
    record += hs

    return record


# ---------------------------------------------------------------------------
# HTTP helpers
# ---------------------------------------------------------------------------
def http_request(method, host, path, user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64)"):
    return f"{method} {path} HTTP/1.1\r\nHost: {host}\r\nUser-Agent: {user_agent}\r\nAccept: */*\r\nConnection: keep-alive\r\n\r\n".encode()


def http_response(status, body, content_type="text/html"):
    resp = f"HTTP/1.1 {status}\r\nContent-Type: {content_type}\r\nContent-Length: {len(body)}\r\nServer: nginx/1.24\r\nConnection: close\r\n\r\n".encode()
    return resp + body


print(f"[*] Generating attack PCAP: {OUTPUT}")

# === PHASE 1: Normal browsing noise with TLS (background, throughout) ===
print("[+] Generating background HTTPS noise with TLS handshakes...")
https_sites = [
    ("www.google.com", "142.250.80.4"),
    ("www.youtube.com", "142.250.80.14"),
    ("cdn.jsdelivr.net", "104.16.85.20"),
    ("fonts.googleapis.com", "142.250.80.10"),
    ("www.reddit.com", "151.101.1.140"),
    ("weather.com", "23.55.163.66"),
    ("news.ycombinator.com", "209.216.230.240"),
    ("stackoverflow.com", "151.101.1.69"),
]
for i in range(40):
    t = random.randint(0, 5640)
    site, site_ip = random.choice(https_sites)
    sport = random.randint(49152, 65535)

    # DNS lookup
    add_pkt(Ether(src=VICTIM_MAC, dst=GW_MAC) /
            IP(src=VICTIM_IP, dst=DNS_SERVER) /
            UDP(sport=random.randint(49152, 65535), dport=53) /
            DNS(rd=1, qd=DNSQR(qname=site)), t)
    add_pkt(Ether(src=GW_MAC, dst=VICTIM_MAC) /
            IP(src=DNS_SERVER, dst=VICTIM_IP) /
            UDP(sport=53, dport=random.randint(49152, 65535)) /
            DNS(qr=1, qd=DNSQR(qname=site),
                an=DNSRR(rrname=site, type="A", rdata=site_ip)), t + 0.01)

    # TCP handshake + TLS
    seq, ack = tcp_handshake(VICTIM_IP, site_ip, VICTIM_MAC, GW_MAC, sport, 443, t + 0.1, ttl=128)
    # TLS Client Hello
    hello = tls_client_hello(site)
    seq, ack = tcp_data(VICTIM_IP, site_ip, VICTIM_MAC, GW_MAC, sport, 443, seq, ack, hello, t + 0.15, ttl=128)
    # TLS Server Hello
    shello = tls_server_hello()
    add_pkt(Ether(src=GW_MAC, dst=VICTIM_MAC) /
            IP(src=site_ip, dst=VICTIM_IP, ttl=64) /
            TCP(sport=443, dport=sport, flags="PA", seq=ack, ack=seq) /
            Raw(load=shello), t + 0.2)
    # Application data (encrypted payload)
    app_data = struct.pack('>B', 23) + struct.pack('>H', 0x0303) + struct.pack('>H', 200) + b'\x00' * 200
    add_pkt(Ether(src=GW_MAC, dst=VICTIM_MAC) /
            IP(src=site_ip, dst=VICTIM_IP, ttl=64) /
            TCP(sport=443, dport=sport, flags="PA", seq=ack + len(shello), ack=seq) /
            Raw(load=app_data), t + 0.25)

# Additional background DNS noise (unresolved/varied)
noise_domains = [
    "api.openai.com", "login.microsoftonline.com", "graph.microsoft.com",
    "update.googleapis.com", "clientservices.googleapis.com",
    "safebrowsing.googleapis.com", "ocsp.pki.goog", "crl.microsoft.com",
]
for i in range(120):
    t = random.randint(0, 5640)
    domain = random.choice(noise_domains)
    add_pkt(Ether(src=VICTIM_MAC, dst=GW_MAC) /
            IP(src=VICTIM_IP, dst=DNS_SERVER) /
            UDP(sport=random.randint(49152, 65535), dport=53) /
            DNS(rd=1, qd=DNSQR(qname=domain)), t)

# === PHASE 2: Initial C2 callback (t+180s = 14:26) ===
print("[+] C2 initial callback with HTTP stager download...")
# DNS lookup for C2
add_pkt(Ether(src=VICTIM_MAC, dst=GW_MAC) /
        IP(src=VICTIM_IP, dst=DNS_SERVER) /
        UDP(sport=51234, dport=53) /
        DNS(rd=1, qd=DNSQR(qname=C2_DOMAIN)), 180)
add_pkt(Ether(src=GW_MAC, dst=VICTIM_MAC) /
        IP(src=DNS_SERVER, dst=VICTIM_IP) /
        UDP(sport=53, dport=51234) /
        DNS(qr=1, qd=DNSQR(qname=C2_DOMAIN),
            an=DNSRR(rrname=C2_DOMAIN, type="A", rdata=C2_IP)), 180.05)

# HTTP GET /stager (full request/response)
sport_c2 = 49200
seq, ack = tcp_handshake(VICTIM_IP, C2_IP, VICTIM_MAC, GW_MAC, sport_c2, 80, 182, ttl=128)
req = http_request("GET", C2_DOMAIN, "/stager", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) PowerShell/5.1")
seq, ack = tcp_data(VICTIM_IP, C2_IP, VICTIM_MAC, GW_MAC, sport_c2, 80, seq, ack, req, 182.5, ttl=128)
# Server response with payload
stager_body = b'powershell -enc ' + b'A' * 500  # simulated encoded payload
resp = http_response("200 OK", stager_body, "application/octet-stream")
add_pkt(Ether(src=GW_MAC, dst=VICTIM_MAC) /
        IP(src=C2_IP, dst=VICTIM_IP, ttl=52) /
        TCP(sport=80, dport=sport_c2, flags="PA", seq=ack, ack=seq) /
        Raw(load=resp), 183)
tcp_fin(VICTIM_IP, C2_IP, VICTIM_MAC, GW_MAC, sport_c2, 80, seq, ack + len(resp), 183.5, ttl=128)

# Second HTTP callback: POST check-in
sport_c2b = 49210
seq2, ack2 = tcp_handshake(VICTIM_IP, C2_IP, VICTIM_MAC, GW_MAC, sport_c2b, 80, 195, ttl=128)
checkin = http_request("POST", C2_DOMAIN, "/api/checkin")
seq2, ack2 = tcp_data(VICTIM_IP, C2_IP, VICTIM_MAC, GW_MAC, sport_c2b, 80, seq2, ack2, checkin, 195.5, ttl=128)
resp2 = http_response("200 OK", b'{"status":"ok","cmd":"recon"}', "application/json")
add_pkt(Ether(src=GW_MAC, dst=VICTIM_MAC) /
        IP(src=C2_IP, dst=VICTIM_IP, ttl=52) /
        TCP(sport=80, dport=sport_c2b, flags="PA", seq=ack2, ack=seq2) /
        Raw(load=resp2), 196)
tcp_fin(VICTIM_IP, C2_IP, VICTIM_MAC, GW_MAC, sport_c2b, 80, seq2, ack2 + len(resp2), 197, ttl=128)

# Third HTTP callback: GET /tasks
sport_c2c = 49220
seq3, ack3 = tcp_handshake(VICTIM_IP, C2_IP, VICTIM_MAC, GW_MAC, sport_c2c, 80, 300, ttl=128)
tasks_req = http_request("GET", C2_DOMAIN, "/api/tasks")
seq3, ack3 = tcp_data(VICTIM_IP, C2_IP, VICTIM_MAC, GW_MAC, sport_c2c, 80, seq3, ack3, tasks_req, 300.5, ttl=128)
resp3 = http_response("200 OK", b'{"tasks":["persist","escalate","exfil"]}', "application/json")
add_pkt(Ether(src=GW_MAC, dst=VICTIM_MAC) /
        IP(src=C2_IP, dst=VICTIM_IP, ttl=52) /
        TCP(sport=80, dport=sport_c2c, flags="PA", seq=ack3, ack=seq3) /
        Raw(load=resp3), 301)
tcp_fin(VICTIM_IP, C2_IP, VICTIM_MAC, GW_MAC, sport_c2c, 80, seq3, ack3 + len(resp3), 302, ttl=128)

# === PHASE 3: Discovery scan (t+720s = 14:35) ===
print("[+] Discovery port scan (SYN sweep)...")
for i in range(1, 30):
    target = f"{INTERNAL_RANGE}.{i}"
    for port in [22, 80, 445, 3389]:
        sport_scan = random.randint(49152, 65535)
        t_scan = 720 + i * 0.5 + port * 0.01
        # SYN
        add_pkt(Ether(src=VICTIM_MAC, dst=GW_MAC) /
                IP(src=VICTIM_IP, dst=target, ttl=128) /
                TCP(sport=sport_scan, dport=port, flags="S"), t_scan)
        # Most get RST (closed), but port 445 on .5 responds
        if target == RELIEF_IP and port == 445:
            add_pkt(Ether(src=GW_MAC, dst=VICTIM_MAC) /
                    IP(src=target, dst=VICTIM_IP, ttl=128) /
                    TCP(sport=port, dport=sport_scan, flags="SA"), t_scan + 0.02)
            add_pkt(Ether(src=VICTIM_MAC, dst=GW_MAC) /
                    IP(src=VICTIM_IP, dst=target, ttl=128) /
                    TCP(sport=sport_scan, dport=port, flags="R"), t_scan + 0.04)
        else:
            add_pkt(Ether(src=GW_MAC, dst=VICTIM_MAC) /
                    IP(src=target, dst=VICTIM_IP, ttl=128) /
                    TCP(sport=port, dport=sport_scan, flags="RA"), t_scan + 0.05)

# === PHASE 4: SMB Lateral Movement (t+1320s = 14:45) ===
print("[+] SMB lateral movement with full protocol negotiation...")
smb_sport = 49300
seq_s, ack_s = tcp_handshake(VICTIM_IP, RELIEF_IP, VICTIM_MAC, GW_MAC, smb_sport, 445, 1320, ttl=128)

# SMB2 Negotiate
neg_req = smb2_negotiate_request()
seq_s, ack_s = tcp_data(VICTIM_IP, RELIEF_IP, VICTIM_MAC, GW_MAC, smb_sport, 445, seq_s, ack_s, neg_req, 1320.5, ttl=128)
neg_resp = smb2_negotiate_response()
add_pkt(Ether(src=GW_MAC, dst=VICTIM_MAC) /
        IP(src=RELIEF_IP, dst=VICTIM_IP, ttl=128) /
        TCP(sport=445, dport=smb_sport, flags="PA", seq=ack_s, ack=seq_s) /
        Raw(load=neg_resp), 1321)
ack_s += len(neg_resp)

# SMB2 Session Setup
ss_req = smb2_session_setup_request()
seq_s, ack_s = tcp_data(VICTIM_IP, RELIEF_IP, VICTIM_MAC, GW_MAC, smb_sport, 445, seq_s, ack_s, ss_req, 1321.5, ttl=128)
ss_resp = smb2_session_setup_response()
add_pkt(Ether(src=GW_MAC, dst=VICTIM_MAC) /
        IP(src=RELIEF_IP, dst=VICTIM_IP, ttl=128) /
        TCP(sport=445, dport=smb_sport, flags="PA", seq=ack_s, ack=seq_s) /
        Raw(load=ss_resp), 1322)
ack_s += len(ss_resp)

# SMB2 Tree Connect to \\10.10.30.5\share
tc_req = smb2_tree_connect_request("\\\\10.10.30.5\\share")
seq_s, ack_s = tcp_data(VICTIM_IP, RELIEF_IP, VICTIM_MAC, GW_MAC, smb_sport, 445, seq_s, ack_s, tc_req, 1322.5, ttl=128)
tc_resp = smb2_tree_connect_response()
add_pkt(Ether(src=GW_MAC, dst=VICTIM_MAC) /
        IP(src=RELIEF_IP, dst=VICTIM_IP, ttl=128) /
        TCP(sport=445, dport=smb_sport, flags="PA", seq=ack_s, ack=seq_s) /
        Raw(load=tc_resp), 1323)
ack_s += len(tc_resp)

# SMB2 Create (open file: relief-ops.xlsx)
cr_req = smb2_create_request("relief-ops.xlsx")
seq_s, ack_s = tcp_data(VICTIM_IP, RELIEF_IP, VICTIM_MAC, GW_MAC, smb_sport, 445, seq_s, ack_s, cr_req, 1323.5, ttl=128)
cr_resp = smb2_create_response()
add_pkt(Ether(src=GW_MAC, dst=VICTIM_MAC) /
        IP(src=RELIEF_IP, dst=VICTIM_IP, ttl=128) /
        TCP(sport=445, dport=smb_sport, flags="PA", seq=ack_s, ack=seq_s) /
        Raw(load=cr_resp), 1324)
ack_s += len(cr_resp)

# SMB2 Read (download file)
rd_req = smb2_read_request()
seq_s, ack_s = tcp_data(VICTIM_IP, RELIEF_IP, VICTIM_MAC, GW_MAC, smb_sport, 445, seq_s, ack_s, rd_req, 1324.5, ttl=128)
rd_resp = smb2_read_response(25600)
add_pkt(Ether(src=GW_MAC, dst=VICTIM_MAC) /
        IP(src=RELIEF_IP, dst=VICTIM_IP, ttl=128) /
        TCP(sport=445, dport=smb_sport, flags="PA", seq=ack_s, ack=seq_s) /
        Raw(load=rd_resp), 1325)
ack_s += len(rd_resp)

# Close connection
tcp_fin(VICTIM_IP, RELIEF_IP, VICTIM_MAC, GW_MAC, smb_sport, 445, seq_s, ack_s, 1330, ttl=128)

# === PHASE 5: DNS C2 Beaconing (t+1620s = 14:50, every 30s) ===
print("[+] DNS C2 beaconing (30s intervals)...")
beacon_start = 1620
for i in range(120):
    t = beacon_start + i * 30
    if t > 5640:
        break
    add_pkt(Ether(src=VICTIM_MAC, dst=GW_MAC) /
            IP(src=VICTIM_IP, dst=DNS_SERVER) /
            UDP(sport=random.randint(49152, 65535), dport=53) /
            DNS(rd=1, qd=DNSQR(qname=f"beacon.{C2_DOMAIN}")), t)
    add_pkt(Ether(src=GW_MAC, dst=VICTIM_MAC) /
            IP(src=DNS_SERVER, dst=VICTIM_IP) /
            UDP(sport=53, dport=random.randint(49152, 65535)) /
            DNS(qr=1, aa=1,
                qd=DNSQR(qname=f"beacon.{C2_DOMAIN}"),
                an=DNSRR(rrname=f"beacon.{C2_DOMAIN}", type="TXT", rdata="OK")), t + 0.05)

# === PHASE 6: DNS Tunneling Exfiltration (t+3420s = 15:00) ===
print("[+] DNS tunneling exfiltration...")
exfil_data = b"-----BEGIN CERTIFICATE-----\nMIIDXTCCAkWgAwIBAgIJAP4LF4VPmNSzMA0GCSqGSIb3DQEBCwUAMEUxCzAJBgNV\nBAYTAlVTMRMwEQYDVQQIDApTb21lLVN0YXRlMSEwHwYDVQQKDBhJbnRlcm5ldCBX\naWRnaXRzIFB0eSBMdGQwHhcNMjQwMTAxMDAwMDAwWhcNMjUwMTAxMDAwMDAwWjBF\n-----END CERTIFICATE-----\n"

chunks = []
for i in range(0, len(exfil_data), 50):
    chunk = base64.b64encode(exfil_data[i:i+50]).decode().rstrip("=")
    chunks.append(chunk)

exfil_start = 3420
for i, chunk in enumerate(chunks):
    t = exfil_start + i * 15
    subdomain = f"{chunk}.data.{C2_DOMAIN}"
    add_pkt(Ether(src=VICTIM_MAC, dst=GW_MAC) /
            IP(src=VICTIM_IP, dst=DNS_SERVER) /
            UDP(sport=random.randint(49152, 65535), dport=53) /
            DNS(rd=1, qd=DNSQR(qname=subdomain)), t)
    add_pkt(Ether(src=GW_MAC, dst=VICTIM_MAC) /
            IP(src=DNS_SERVER, dst=VICTIM_IP) /
            UDP(sport=53, dport=random.randint(49152, 65535)) /
            DNS(qr=1, qd=DNSQR(qname=subdomain),
                an=DNSRR(rrname=subdomain, type="A", rdata="127.0.0.1")), t + 0.03)

# === PHASE 7: C2 HTTPS callbacks (t+2400-5400, periodic) ===
print("[+] Periodic C2 HTTPS callbacks...")
for i in range(8):
    t = 2400 + i * 380 + random.randint(-30, 30)
    if t > 5640:
        break
    sport_https = random.randint(49500, 65000)
    # DNS for C2
    add_pkt(Ether(src=VICTIM_MAC, dst=GW_MAC) /
            IP(src=VICTIM_IP, dst=DNS_SERVER) /
            UDP(sport=random.randint(49152, 65535), dport=53) /
            DNS(rd=1, qd=DNSQR(qname=C2_DOMAIN)), t - 1)
    # TLS to C2
    seq_h, ack_h = tcp_handshake(VICTIM_IP, C2_IP, VICTIM_MAC, GW_MAC, sport_https, 443, t, ttl=128)
    hello = tls_client_hello(C2_DOMAIN)
    seq_h, ack_h = tcp_data(VICTIM_IP, C2_IP, VICTIM_MAC, GW_MAC, sport_https, 443, seq_h, ack_h, hello, t + 0.1, ttl=128)
    shello = tls_server_hello()
    add_pkt(Ether(src=GW_MAC, dst=VICTIM_MAC) /
            IP(src=C2_IP, dst=VICTIM_IP, ttl=52) /
            TCP(sport=443, dport=sport_https, flags="PA", seq=ack_h, ack=seq_h) /
            Raw(load=shello), t + 0.15)
    # Encrypted app data
    app_data = struct.pack('>B', 23) + struct.pack('>H', 0x0303) + struct.pack('>H', 500) + b'\x00' * 500
    add_pkt(Ether(src=GW_MAC, dst=VICTIM_MAC) /
            IP(src=C2_IP, dst=VICTIM_IP, ttl=52) /
            TCP(sport=443, dport=sport_https, flags="PA", seq=ack_h + len(shello), ack=seq_h) /
            Raw(load=app_data), t + 0.2)

# === Sort and write ===
packets.sort(key=lambda p: p.time)
print(f"[+] Writing {len(packets)} packets to {OUTPUT}")
wrpcap(OUTPUT, packets)

# Stats
total_time = (packets[-1].time - packets[0].time)
print(f"[*] PCAP spans {total_time:.0f} seconds ({total_time/60:.0f} minutes)")
print(f"[*] Background HTTPS sessions: ~40 (with TLS handshakes)")
print(f"[*] HTTP C2 sessions: 3 (stager + checkin + tasks)")
print(f"[*] HTTPS C2 callbacks: ~8 (encrypted)")
print(f"[*] DNS beacons: ~{min(120, (5640-beacon_start)//30)} (30s interval)")
print(f"[*] DNS exfil queries: {len(chunks)} (base64 chunks)")
print(f"[*] SMB sessions: 1 (full negotiate+session+tree+read to {RELIEF_IP})")
print(f"[*] Discovery scan targets: 29 hosts, 4 ports each")
print(f"[*] Expected Zeek logs: conn, dns, http, ssl, smb, files, weird")
print(f"[*] Done.")
