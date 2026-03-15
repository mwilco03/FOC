**Lesson-by-lesson breakdown of Module 14 – Remote Access & File Transfer Protocols**
---

## Module 14 – Remote Access & File Transfer Protocols

---

## Lesson 1: Telnet

### Key Concepts

* Telnet provides **remote command-line access** to network devices
* Uses **TCP port 23**
* All data transmitted in **cleartext** — including usernames and passwords
* **Legacy protocol** — should be replaced with SSH in all production environments
* Still found on older networking equipment, IoT devices, and lab environments

### How Telnet Works

| Step | Description |
|------|-------------|
| 1 | Client initiates TCP connection to port 23 |
| 2 | Server sends banner/login prompt |
| 3 | Client sends username in **plaintext** |
| 4 | Server requests password |
| 5 | Client sends password in **plaintext** |
| 6 | Server grants shell access |

### Cisco IOS Configuration (VTY Lines)

```cisco
! Configure Telnet access on VTY lines
line vty 0 4
  password CiscoLab123
  login
  transport input telnet

! Verify Telnet connections
show users
show line vty 0 4
```

### Why Telnet Is Dangerous

```
Packet Capture (Wireshark):
Frame 1: Client → Server  "admin"
Frame 2: Server → Client  "Password:"
Frame 3: Client → Server  "p@ssw0rd!"     ← VISIBLE IN CLEARTEXT
```

* **Anyone on the same network segment** can sniff credentials with Wireshark or tcpdump
* **No encryption** — vulnerable to man-in-the-middle attacks
* **No integrity checking** — commands can be injected in transit
* **No server authentication** — client cannot verify it's talking to the real server

### Telnet Commands

```bash
# Connect to a device
telnet 192.168.1.1

# Specify port (useful for testing services)
telnet 192.168.1.1 80
telnet 192.168.1.1 25

# Windows
telnet 10.0.0.1

# Check if Telnet client is installed (Windows)
dism /online /Get-Features | findstr Telnet
```

### Security Considerations

* **NEVER use Telnet over untrusted networks**
* Replace with SSH on all production devices
* If Telnet is required for legacy equipment, restrict access with ACLs
* Monitor for Telnet traffic on your network — it may indicate misconfiguration or compromise

```cisco
! Disable Telnet, allow only SSH
line vty 0 4
  transport input ssh
```

---

## Lesson 2: SSH (Secure Shell)

### Key Concepts

* SSH provides **encrypted remote access** — the secure replacement for Telnet
* Uses **TCP port 22**
* All traffic is **encrypted** — credentials, commands, and output
* Two versions: SSHv1 (broken, never use) and **SSHv2** (current standard)
* Provides **authentication**, **encryption**, and **integrity**

### SSH vs Telnet

| Feature | Telnet | SSH |
|---------|--------|-----|
| **Port** | 23 | 22 |
| **Encryption** | None | AES, ChaCha20 |
| **Authentication** | Password only (plaintext) | Password, public key, certificates |
| **Integrity** | None | HMAC |
| **Server verification** | None | Host key fingerprint |
| **Use in production** | NEVER | ALWAYS |

### SSH Authentication Methods

| Method | Description | Security Level |
|--------|-------------|----------------|
| **Password** | Username + password over encrypted channel | Good |
| **Public Key** | RSA/Ed25519 key pair — no password sent | Better |
| **Certificate** | CA-signed keys — scalable for enterprises | Best |

### SSH Key Exchange Process

| Step | Description |
|------|-------------|
| 1 | Client connects to TCP port 22 |
| 2 | Server sends SSH banner (`SSH-2.0-OpenSSH_8.9p1`) |
| 3 | Key exchange (Diffie-Hellman) — agree on session key |
| 4 | Server authentication — client verifies host key |
| 5 | User authentication — password or public key |
| 6 | Encrypted session established |

### SSH Commands

```bash
# Basic connection
ssh admin@192.168.1.1

# Specify port
ssh -p 2222 admin@192.168.1.1

# Generate SSH key pair
ssh-keygen -t ed25519 -C "admin@corp"

# Copy public key to server
ssh-copy-id admin@192.168.1.1

# SSH with verbose output (troubleshooting)
ssh -v admin@192.168.1.1

# SSH tunneling / port forwarding
ssh -L 8080:internal-server:80 admin@jump-host

# SCP — secure file copy over SSH
scp file.txt admin@192.168.1.1:/home/admin/
scp admin@192.168.1.1:/var/log/syslog ./local-copy.log

# SFTP — secure FTP over SSH
sftp admin@192.168.1.1
```

### Cisco IOS Configuration

```cisco
! Generate RSA keys (required for SSH)
crypto key generate rsa modulus 2048

! Configure SSH version 2
ip ssh version 2
ip ssh time-out 60
ip ssh authentication-retries 3

! Set hostname and domain (required for key generation)
hostname Router1
ip domain-name corp.local

! Configure VTY lines for SSH only
line vty 0 4
  transport input ssh
  login local

! Create local user
username admin privilege 15 secret SecurePass123!

! Verify SSH
show ip ssh
show ssh
```

### SSH Security Best Practices

* **Disable SSHv1** — use only SSHv2
* **Use key-based authentication** — disable password auth when possible
* **Change default port** if exposed to internet (security through obscurity, not a substitute for real security)
* **Use fail2ban** or similar to block brute-force attempts
* **Rotate keys** periodically and audit `authorized_keys` files

### Troubleshooting SSH

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Connection refused | SSH not running or wrong port | `systemctl status sshd`, check port |
| Host key changed warning | Server reinstalled or MITM attack | Verify with admin, then `ssh-keygen -R host` |
| Permission denied (publickey) | Wrong key or permissions | Check `~/.ssh/` permissions (700), key file (600) |
| Connection timeout | Firewall blocking port 22 | Check `iptables`, security groups, ACLs |

---

## Lesson 3: FTP (File Transfer Protocol)

### Key Concepts

* FTP transfers files between hosts over a network
* Uses **TCP port 21** (control) and **TCP port 20** (data — active mode)
* Credentials and data sent in **cleartext** — same risk as Telnet
* Two modes: **Active** and **Passive**
* Should be replaced with **SFTP** or **FTPS** in production

### FTP Modes

| Mode | Control Channel | Data Channel | Firewall Friendly? |
|------|----------------|--------------|-------------------|
| **Active** | Client → Server:21 | Server:20 → Client:random | No — server initiates data connection |
| **Passive** | Client → Server:21 | Client:random → Server:random | Yes — client initiates both connections |

### FTP Command Sequence

| Step | Command | Direction | Description |
|------|---------|-----------|-------------|
| 1 | Connect | Client → Server:21 | TCP handshake |
| 2 | `220` | Server → Client | Banner / welcome message |
| 3 | `USER admin` | Client → Server | Send username (cleartext) |
| 4 | `331` | Server → Client | Password required |
| 5 | `PASS secret` | Client → Server | Send password (**cleartext!**) |
| 6 | `230` | Server → Client | Login successful |
| 7 | `RETR file.txt` | Client → Server | Download file |
| 8 | `QUIT` | Client → Server | End session |

### FTP Response Codes

| Code | Meaning |
|------|---------|
| **220** | Service ready / welcome |
| **230** | Login successful |
| **331** | Username OK, need password |
| **425** | Can't open data connection |
| **426** | Connection closed, transfer aborted |
| **530** | Not logged in / auth failed |
| **550** | File not found / permission denied |

### FTP Commands

```bash
# Connect to FTP server
ftp 192.168.1.100

# Anonymous FTP login
ftp> open 192.168.1.100
Name: anonymous
Password: email@example.com

# Common FTP commands
ftp> ls                    # List files
ftp> cd /uploads           # Change directory
ftp> get report.pdf        # Download file
ftp> put backup.tar.gz     # Upload file
ftp> mget *.log            # Download multiple files
ftp> binary                # Switch to binary mode
ftp> ascii                 # Switch to ASCII mode
ftp> bye                   # Disconnect
```

### Secure Alternatives

| Protocol | Port | Description |
|----------|------|-------------|
| **SFTP** | 22 | FTP over SSH — encrypted, uses SSH infrastructure |
| **FTPS** | 990 (implicit) / 21 (explicit) | FTP over TLS/SSL — encrypts the FTP channel |
| **SCP** | 22 | Simple file copy over SSH — no directory listing |

### Cisco IOS — FTP for Config Backup

```cisco
! Configure router as FTP client
ip ftp username admin
ip ftp password SecurePass123!

! Copy running config to FTP server
copy running-config ftp://192.168.1.200/router-backup.cfg

! Copy from FTP to router
copy ftp://192.168.1.200/new-config.cfg running-config
```

### Security Considerations

* FTP sends credentials in **cleartext** — easily captured with Wireshark
* **Anonymous FTP** allows unauthenticated access — disable unless intentional
* Attackers use FTP for **data exfiltration** — transferring stolen files off the network
* FTP **bounce attacks** abuse active mode to scan ports through the FTP server
* **Always use SFTP or FTPS** in production environments

---

## Lesson 4: Identifying Malicious Traffic Patterns

### Key Concepts

* Attackers use these protocols to establish **reverse shells**, **transfer tools**, and **exfiltrate data**
* Understanding normal traffic helps you **detect anomalies**
* Common attack tools leave **recognizable signatures** in network traffic

### Common Suspicious Port Usage

| Port | Legitimate Use | Suspicious Use |
|------|---------------|----------------|
| **21** | FTP file transfer | Cleartext credential theft, data exfiltration |
| **22** | SSH remote access | Brute force attempts, lateral movement |
| **23** | Telnet (legacy) | Credential sniffing, unauthorized access |
| **4444** | None standard | **Metasploit default reverse shell** |
| **5555** | None standard | Common backdoor / reverse shell |
| **1337** | None standard | Classic "leet" backdoor port |
| **8443** | Alt HTTPS | C2 (Command & Control) callback |
| **53** | DNS | DNS tunneling / data exfiltration |

### Metasploit Reverse Shell — What to Look For (Port 4444)

Metasploit's default `meterpreter/reverse_tcp` payload connects back to the attacker on **TCP port 4444**.

**Traffic pattern:**

| Step | Direction | Description |
|------|-----------|-------------|
| 1 | Victim → Attacker:4444 | SYN — victim initiates outbound connection |
| 2 | Attacker:4444 → Victim | SYN-ACK — attacker accepts |
| 3 | Victim → Attacker:4444 | ACK — handshake complete |
| 4 | Attacker → Victim | Stage 1 payload delivery (often large PSH-ACK) |
| 5 | Bidirectional | Encrypted Meterpreter session — interactive shell |

**Detection indicators:**
* **Outbound connection to port 4444** from an internal host
* **Large initial data transfer** from attacker → victim (stage delivery)
* **Persistent connection** — session stays open for extended periods
* **Encrypted/obfuscated payload** — not matching any known application protocol
* **Unusual process** spawning the connection (e.g., `cmd.exe` from a web server)

### Wireshark Filters for Detection

```
# Find Metasploit default reverse shell traffic
tcp.port == 4444

# Find Telnet sessions (should not exist in production)
tcp.port == 23

# Find cleartext FTP credentials
ftp.request.command == "PASS"

# Find SSH brute force (many auth attempts)
ssh && tcp.flags.syn == 1

# Find connections to non-standard high ports
tcp.dstport > 1024 && tcp.dstport < 10000 && tcp.flags.syn == 1

# Find large outbound transfers (potential exfiltration)
ip.src == 10.0.0.0/8 && tcp.len > 1000
```

### Network Forensics Workflow

1. **Baseline** — Know what normal traffic looks like
2. **Filter** — Isolate suspicious protocols/ports
3. **Follow the stream** — Reconstruct full conversations
4. **Decode payloads** — Look at hex dumps for shellcode signatures
5. **Correlate** — Match network events with host logs
6. **Document** — Record findings with timestamps and evidence

---

## Summary of Remote Access Protocols

| Protocol | Port(s) | Encrypted | Authentication | Use Case |
|----------|---------|-----------|----------------|----------|
| **Telnet** | 23 | No | Password (cleartext) | Legacy only — never in production |
| **SSH** | 22 | Yes (AES, ChaCha20) | Password, key, certificate | Secure remote access (always use this) |
| **FTP** | 21/20 | No | Password (cleartext) | Legacy file transfer |
| **SFTP** | 22 | Yes (SSH) | Same as SSH | Secure file transfer (use this) |
| **FTPS** | 990/21 | Yes (TLS) | Certificate + password | Secure FTP over TLS |

---

## Module 14 Objectives Covered

| Objective | Met By |
|-----------|--------|
| Understand Telnet risks | Cleartext demo + security analysis |
| Configure SSH on Cisco devices | IOS SSH setup + VTY configuration |
| Compare authentication methods | SSH password vs key vs certificate |
| Understand FTP operations | Active/passive modes + command sequence |
| Identify secure alternatives | SFTP, FTPS, SCP comparison |
| Detect malicious traffic patterns | Port 4444 reverse shell analysis + Wireshark filters |
