#!/usr/bin/env python3
"""Lightweight DNS server for CTF lab (replaces dnsmasq which has issues in Docker)."""

import socket
import struct

RECORDS_TXT = {
    'flag.corp.local': 'FLAG{dns_txt_record_found}',
    'corp.local': 'Corp Lab DNS',
}

RECORDS_A = {
    'web.corp.local': '172.20.1.10',
    'mail.corp.local': '172.20.1.20',
    'files.corp.local': '172.20.1.30',
}

def parse_qname(data, offset=12):
    parts = []
    i = offset
    while data[i] != 0:
        length = data[i]
        parts.append(data[i+1:i+1+length].decode())
        i += length + 1
    return '.'.join(parts), i + 1

def get_qtype(data, qname_end):
    return struct.unpack('>H', data[qname_end:qname_end+2])[0]

def build_response(query, qname, qtype):
    tid = query[:2]
    qname_end_offset = 12
    i = 12
    while query[i] != 0:
        i += query[i] + 1
    i += 1
    qname_end_offset = i
    question = query[12:qname_end_offset + 4]

    if qtype == 16 and qname in RECORDS_TXT:
        txt = RECORDS_TXT[qname].encode()
        rdata = bytes([len(txt)]) + txt
        flags = b'\x81\x80'
        header = tid + flags + b'\x00\x01\x00\x01\x00\x00\x00\x00'
        answer = b'\xc0\x0c' + struct.pack('>HHiH', 16, 1, 3600, len(rdata)) + rdata
        return header + question + answer

    if qtype == 1 and qname in RECORDS_A:
        ip_bytes = socket.inet_aton(RECORDS_A[qname])
        flags = b'\x81\x80'
        header = tid + flags + b'\x00\x01\x00\x01\x00\x00\x00\x00'
        answer = b'\xc0\x0c' + struct.pack('>HHiH', 1, 1, 3600, 4) + ip_bytes
        return header + question + answer

    # NXDOMAIN
    flags = b'\x81\x83'
    header = tid + flags + b'\x00\x01\x00\x00\x00\x00\x00\x00'
    return header + question

def handle_tcp_client(conn):
    """Handle DNS-over-TCP (length-prefixed messages)."""
    import threading
    try:
        conn.settimeout(5)
        raw = conn.recv(514)
        if len(raw) < 4:
            return
        msg_len = struct.unpack('>H', raw[:2])[0]
        data = raw[2:2+msg_len]
        qname, qname_end = parse_qname(data)
        qtype = get_qtype(data, qname_end)
        resp = build_response(data, qname, qtype)
        conn.sendall(struct.pack('>H', len(resp)) + resp)
    except Exception:
        pass
    finally:
        conn.close()

def tcp_listener():
    """TCP DNS listener so nmap sees port 5353/tcp open."""
    import threading
    tcp = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    tcp.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    tcp.bind(('0.0.0.0', 5353))
    tcp.listen(5)
    print('[+] DNS TCP listener on port 5353')
    while True:
        conn, _ = tcp.accept()
        threading.Thread(target=handle_tcp_client, args=(conn,), daemon=True).start()

def main():
    import threading
    # Start TCP listener in background
    threading.Thread(target=tcp_listener, daemon=True).start()

    # UDP listener (main)
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind(('0.0.0.0', 5353))
    print('[+] DNS server on port 5353 (UDP+TCP)')

    while True:
        try:
            data, addr = sock.recvfrom(512)
            qname, qname_end = parse_qname(data)
            qtype = get_qtype(data, qname_end)
            resp = build_response(data, qname, qtype)
            sock.sendto(resp, addr)
        except Exception as e:
            print(f'DNS error: {e}')

if __name__ == '__main__':
    main()
