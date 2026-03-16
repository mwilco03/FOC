#!/usr/bin/env python3
"""SMTP-like challenge server on port 2525.
Students must manually perform an SMTP conversation with nc to get the flag.
Teaches: protocol interaction, not just banner grabbing.

Expected conversation:
  nc 172.20.1.20 2525
  220 mail.corp.local SMTP Challenge Server
  HELO student
  250 Hello student, pleased to meet you
  MAIL FROM:<student@lab>
  250 OK
  RCPT TO:<flag@corp.local>
  250 OK - FLAG{smtp_conversation_complete}
"""

import socket
import threading

def handle_client(conn, addr):
    try:
        conn.sendall(b"220 mail.corp.local SMTP Challenge Server - Talk to me.\r\n")
        state = "greeting"

        while True:
            conn.settimeout(30)
            try:
                data = conn.recv(1024).decode().strip()
            except:
                break

            if not data:
                break

            upper = data.upper()

            if state == "greeting":
                if upper.startswith("HELO") or upper.startswith("EHLO"):
                    name = data.split(" ", 1)[1] if " " in data else "stranger"
                    conn.sendall(f"250 Hello {name}, pleased to meet you\r\n".encode())
                    state = "helo"
                elif upper == "QUIT":
                    conn.sendall(b"221 Bye\r\n")
                    break
                else:
                    conn.sendall(b"503 Say HELO first\r\n")

            elif state == "helo":
                if upper.startswith("MAIL FROM"):
                    conn.sendall(b"250 OK sender accepted\r\n")
                    state = "mail"
                elif upper == "QUIT":
                    conn.sendall(b"221 Bye\r\n")
                    break
                else:
                    conn.sendall(b"503 Need MAIL FROM:<address>\r\n")

            elif state == "mail":
                if upper.startswith("RCPT TO"):
                    conn.sendall(b"250 OK - FLAG{smtp_conversation_complete}\r\n")
                    state = "rcpt"
                elif upper == "QUIT":
                    conn.sendall(b"221 Bye\r\n")
                    break
                else:
                    conn.sendall(b"503 Need RCPT TO:<address>\r\n")

            elif state == "rcpt":
                if upper == "DATA":
                    conn.sendall(b"354 Go ahead (but there's nothing more here)\r\n")
                elif upper == "QUIT":
                    conn.sendall(b"221 Bye - nice work!\r\n")
                    break
                else:
                    conn.sendall(b"250 OK\r\n")
    except:
        pass
    finally:
        conn.close()

def main():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(("0.0.0.0", 2525))
    s.listen(5)
    print("[+] SMTP challenge on port 2525")
    while True:
        c, a = s.accept()
        threading.Thread(target=handle_client, args=(c, a), daemon=True).start()

if __name__ == "__main__":
    main()
