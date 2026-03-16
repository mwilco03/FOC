# Nmap Training Lab

A Docker Compose training environment for teaching nmap to a class of ~10 students. Students access web-based terminals through a load balancer, scan a network of target microservices, and submit flags to CTFd.

## Architecture

```
Browser :80   --> Traefik (sticky sessions) --> 10x Shell-in-a-Box (nmap inside)
Browser :8000 --> CTFd (scoreboard + challenges)

Networks:
  student_net  (172.20.0.0/24) - Traefik + student terminals
  target_net   (172.20.1.0/24) - 12 target services + student terminals
  ctfd_net     (172.20.2.0/24) - CTFd + MariaDB + Redis
```

## Quick Start

```bash
# 1. Start everything
docker compose up -d --build

# 2. Wait for all services to be healthy (~60 seconds)
docker compose ps

# 3. Access student terminal
open http://localhost        # Load-balanced (sticky session)
open http://localhost:4201   # Direct to student-1
# ... ports 4201-4210 for students 1-10

# 4. Access CTFd scoreboard
open http://localhost:8000

# 5. Complete CTFd setup wizard in browser, generate API token, then seed challenges:
chmod +x ctfd/setup.sh
./ctfd/setup.sh http://localhost:8000 YOUR_API_TOKEN
```

## Target Services

| Service | IP | Ports | Description |
|---------|-----|-------|-------------|
| web-nginx | 172.20.1.10 | 80 | Nginx with flag in HTML source |
| web-apache | 172.20.1.11 | 8888 | Apache on non-standard port |
| db-mysql | 172.20.1.20 | 3306 | MySQL 8.0 |
| db-postgres | 172.20.1.21 | 5432 | PostgreSQL 16 |
| db-redis | 172.20.1.22 | 6379 | Redis (no auth!) |
| db-mongo | 172.20.1.23 | 27017 | MongoDB 7 |
| mail-server | 172.20.1.30 | 25, 143 | Postfix + Dovecot |
| ftp-server | 172.20.1.40 | 21 | vsftpd (anonymous login) |
| ssh-server | 172.20.1.50 | 2222 | OpenSSH on non-standard port |
| dns-server | 172.20.1.60 | 53 | dnsmasq with TXT record flag |
| custom-app | 172.20.1.70 | 4444,5555,6666,9999 | Multi-port app with banners |
| hidden-service | 172.20.1.80 | 31337,65000 TCP + 4444 UDP | High ports + UDP |
| netcat-box | 172.20.1.90 | (none listening) | Netcat utility container |

## CTFd Challenges

20 challenges across 5 categories (3450 total points):

- **Host Discovery** (2 challenges, 100 pts) - Ping sweeps, finding hosts
- **Port Scanning** (4 challenges, 550 pts) - Non-standard ports, counting services
- **Service Detection** (4 challenges, 600 pts) - Version detection, banner grabbing
- **Advanced Scanning** (4 challenges, 900 pts) - High ports, UDP, timing
- **NSE Scripts** (6 challenges, 1200 pts) - Script-based enumeration

## Student Access

- **Load balanced**: `http://<host>:80` - Traefik assigns sticky session
- **Direct access**: `http://<host>:4201` through `http://<host>:4210`
- **Credentials**: username `student`, password `student`

## Resource Requirements

- RAM: ~4-6 GB
- CPU: 4+ cores recommended
- Disk: ~20 GB

## Teardown

```bash
docker compose down -v    # Stop and remove volumes
```
