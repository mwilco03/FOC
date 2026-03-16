#!/usr/bin/env python3
"""Minimal FTP server with anonymous access and flag in banner."""

import socket
import threading
import os

BANNER = "220 Welcome to Corp File Server FTP - FLAG{ftp_anonymous_access}\r\n"
FTP_ROOT = "/var/ftp"

def handle(conn, addr):
    try:
        conn.sendall(BANNER.encode())
        while True:
            conn.settimeout(30)
            data = conn.recv(1024).decode().strip()
            if not data:
                break
            cmd = data.upper().split()[0] if data.split() else ""
            if cmd == "USER":
                conn.sendall(b"230 Anonymous access granted.\r\n")
            elif cmd == "SYST":
                conn.sendall(b"215 UNIX Type: L8\r\n")
            elif cmd == "PWD":
                conn.sendall(b'257 "/"\r\n')
            elif cmd == "LIST" or cmd == "NLST":
                conn.sendall(b"150 Opening data connection.\r\n")
                conn.sendall(b"226 Transfer complete.\r\n")
            elif cmd == "QUIT":
                conn.sendall(b"221 Goodbye.\r\n")
                break
            elif cmd == "FEAT":
                conn.sendall(b"211 End\r\n")
            elif cmd == "TYPE":
                conn.sendall(b"200 Type set.\r\n")
            elif cmd == "PASV":
                conn.sendall(b"227 Entering Passive Mode (0,0,0,0,117,48).\r\n")
            else:
                conn.sendall(f"500 Unknown command: {data}\r\n".encode())
    except:
        pass
    finally:
        conn.close()

def main():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(("0.0.0.0", 21))
    s.listen(5)
    print("[+] FTP server on port 21")
    while True:
        c, a = s.accept()
        threading.Thread(target=handle, args=(c, a), daemon=True).start()

if __name__ == "__main__":
    main()
