#!/usr/bin/env python3
"""DNS training server - serves flag via TCP banner on port 5353."""

import socket
import threading

BANNER = (
    "DNS Training Lab Server\r\n"
    "TXT record for flag.training.lab: FLAG{dns_txt_record_found}\r\n"
    "Query with: dig @<this_ip> -p 5353 flag.training.lab TXT\r\n"
)

def handle_client(conn, addr):
    try:
        conn.sendall(BANNER.encode())
        conn.settimeout(3)
        try:
            conn.recv(1024)
        except socket.timeout:
            pass
    except (BrokenPipeError, ConnectionResetError):
        pass
    finally:
        conn.close()

def main():
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind(("0.0.0.0", 5353))
    sock.listen(5)
    print("[+] DNS flag server listening on TCP 5353")
    while True:
        conn, addr = sock.accept()
        t = threading.Thread(target=handle_client, args=(conn, addr))
        t.daemon = True
        t.start()

if __name__ == "__main__":
    main()
