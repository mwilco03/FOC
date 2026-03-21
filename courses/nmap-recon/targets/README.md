# Target Hosts — Directory Index

This directory contains Dockerfiles and scripts for all target hosts in the nmap training lab. Some directories are actively used by `docker-compose.yml`; others are standalone templates or archived from earlier iterations.

## Active Targets (deployed by docker-compose.yml)

These directories are built and run as part of the lab:

| Directory | Compose Service | IP | Role |
|-----------|----------------|-----|------|
| `webserver/` | webserver | 172.20.1.10 | SSH, HTTP, MySQL, Dev Portal (8888) |
| `mailserver/` | mailserver | 172.20.1.20 | SSH, SMTP, POP3, IMAP, Webmail (443 SSL) |
| `fileserver/` | fileserver | 172.20.1.30 | FTP (anon), SSH, SMB (139/445) |
| `database/` | database | 172.20.1.40 | SSH, MySQL, PostgreSQL, Redis |
| `devbox/` | devbox | 172.20.1.50 | SSH (2222), DNS (5353), Apps (4444/5555/6666/9999) |
| `hardened/` | hardened | 172.20.1.60 | ICMP blocked, SSH (22222), port knock, elite ports |
| `distractors/` | printer, camera, monitoring, iot-hvac, testserver, vpn, voip | 172.20.1.100-106 | No flags — realistic network noise |

## Archived / Template Directories (not deployed)

These directories are **not** referenced by `docker-compose.yml`. They exist as standalone templates, earlier iterations, or building blocks for future courses. Do not delete them.

| Directory | Why it exists |
|-----------|--------------|
| `mail-server/` | Earlier simplified mail target (postfix + dovecot only). Superseded by `mailserver/` which adds SSH, nginx SSL, SMTP challenge. |
| `ftp-server/` | Standalone FTP target. Functionality merged into `fileserver/` which combines FTP + SSH + SMB. |
| `ssh-server/` | Standalone SSH on non-standard port (2222) with ICMP blocking. Similar functionality in `hardened/` and `devbox/`. |
| `dns-server/` | Standalone DNS target (dnsmasq + Python banner). DNS functionality included in `devbox/`. |
| `custom-app/` | Multi-port Python banner services. Same services included in `devbox/`. |
| `hidden-service/` | Elite ports (31337, 65000) and UDP service. Merged into `hardened/`. |
| `netcat-box/` | Single ncat listener on port 2. Port 2 service included in `hardened/`. |
| `webserver-nginx/` | Apache on non-standard port 8888. Web functionality included in `webserver/`. |
| `webserver-apache/` | Alternate Apache config. Not currently used. |
