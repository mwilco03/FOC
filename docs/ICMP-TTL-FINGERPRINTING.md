# ICMP TTL Fingerprinting and Evasion Techniques

## Overview

Different operating systems use different default TTL (Time To Live) values in their ICMP packets, allowing for OS fingerprinting. This document covers how to craft ICMP packets that mimic different operating systems.

## Default TTL Values by OS

| Operating System | Default ICMP TTL | ICMP Echo Reply Size |
|-----------------|------------------|---------------------|
| Windows (7/8/10/11) | 128 | 32 bytes data |
| Linux (modern) | 64 | 56 bytes data |
| FreeBSD/OpenBSD | 64 | 56 bytes data |
| macOS | 64 | 56 bytes data |
| Cisco IOS | 255 | varies |
| Old Unix systems | 255 | varies |

## Packet Size Differences

### Windows ICMP Echo Request:
```
IP Header: 20 bytes
ICMP Header: 8 bytes
ICMP Data: 32 bytes
Total: 60 bytes
```

### Linux ICMP Echo Request:
```
IP Header: 20 bytes
ICMP Header: 8 bytes
ICMP Data: 56 bytes
Total: 84 bytes
```

## Crafting False TTL/Size Responses

### Using Scapy (Python)

```python
#!/usr/bin/env python3
from scapy.all import *

# Craft a Windows-like ICMP reply
def send_windows_icmp(target_ip, source_ip):
    # Windows: TTL=128, 32 bytes data
    icmp_data = b'abcdefghijklmnopqrstuvwabcdefgh'  # 32 bytes
    packet = IP(src=source_ip, dst=target_ip, ttl=128)/\
             ICMP(type=0, code=0)/\
             Raw(load=icmp_data)
    send(packet, verbose=0)
    print(f"Sent Windows-like ICMP to {target_ip}")

# Craft a Linux-like ICMP reply
def send_linux_icmp(target_ip, source_ip):
    # Linux: TTL=64, 56 bytes data
    icmp_data = b'!' * 48 + b'\x00' * 8  # 56 bytes total
    packet = IP(src=source_ip, dst=target_ip, ttl=64)/\
             ICMP(type=0, code=0)/\
             Raw(load=icmp_data)
    send(packet, verbose=0)
    print(f"Sent Linux-like ICMP to {target_ip}")

# Example usage:
# send_windows_icmp("10.0.0.1", "10.0.0.100")
# send_linux_icmp("10.0.0.1", "10.0.0.100")
```

### Using hping3 (Command Line)

```bash
# Send Windows-like ICMP (TTL=128, 32 bytes data)
hping3 -1 -c 1 -d 32 -t 128 <target_ip>

# Send Linux-like ICMP (TTL=64, 56 bytes data)
hping3 -1 -c 1 -d 56 -t 64 <target_ip>

# Send Cisco-like ICMP (TTL=255)
hping3 -1 -c 1 -t 255 <target_ip>
```

### Using ping with TTL manipulation

```bash
# Linux - set specific TTL (requires raw socket / root)
ping -t 128 -s 32 <target>  # Mimic Windows

# Windows - set specific TTL
ping -i 64 -l 56 <target>   # Mimic Linux
```

## ICMP Tunneling with False Fingerprints

### ptunnel (ICMP Tunnel)

```bash
# Server side (pretend to be Windows)
ptunnel -x password

# Client side
ptunnel -p <server_ip> -lp 8000 -da <dest_ip> -dp 22 -x password

# Then SSH through tunnel:
ssh -p 8000 user@localhost
```

### icmptunnel

```bash
# Server (set TTL in response)
icmptunnel -s

# Client
icmptunnel -c <server_ip>
```

## Evasion Techniques

### 1. **TTL Randomization**
Randomize TTL values to avoid pattern detection:

```python
import random
from scapy.all import *

def random_ttl_icmp(target):
    ttl_values = [64, 128, 255]  # Common OS TTLs
    ttl = random.choice(ttl_values)
    packet = IP(dst=target, ttl=ttl)/ICMP()
    send(packet)
```

### 2. **Incremental TTL (Traceroute-like)**
Gradually increment TTL to appear like legitimate traceroute:

```python
for ttl in range(1, 31):
    packet = IP(dst=target, ttl=ttl)/ICMP()
    reply = sr1(packet, timeout=1, verbose=0)
    if reply:
        print(f"TTL {ttl}: {reply.src}")
```

### 3. **Fragmentation**
Fragment ICMP packets to evade IDS:

```bash
hping3 -1 -c 1 -d 1400 --frag <target>
```

### 4. **Spoofed Source IP with Correct TTL**
Make it look like responses are coming from a specific OS:

```python
# Spoof as Windows host
packet = IP(src="192.168.1.100", dst=target, ttl=128)/ICMP()
send(packet)
```

## Detection Avoidance

### Matching Expected Behavior

If you know the target expects Windows clients:
```python
# Send packets that match Windows fingerprint
def windows_ping(target):
    packet = IP(dst=target, ttl=128)/\
             ICMP()/\
             Raw(load=b'abcdefghijklmnopqrstuvwabcdefgh')
    return sr1(packet, timeout=2)
```

If target expects Linux:
```python
# Send packets that match Linux fingerprint
def linux_ping(target):
    packet = IP(dst=target, ttl=64)/\
             ICMP()/\
             Raw(load=b'!' * 56)
    return sr1(packet, timeout=2)
```

## Potential Lab Hop: "PHANTOM" (ICMP Evasion)

**Concept**: A container that only responds to ICMP packets matching a specific OS fingerprint.

### Challenge Container Setup:
```python
# Container listens for ICMP, only responds to "Windows-like" packets
from scapy.all import *

def packet_callback(pkt):
    if ICMP in pkt and pkt[ICMP].type == 8:  # Echo request
        # Check if TTL and size match Windows
        if pkt[IP].ttl >= 120 and len(pkt[Raw].load) == 32:
            # Valid Windows fingerprint, send flag
            send(IP(dst=pkt[IP].src)/ICMP(type=0)/Raw(load=b"PIVOT{phantom_xxxxx}"))
        else:
            # Wrong fingerprint, send decoy
            send(IP(dst=pkt[IP].src)/ICMP(type=0)/Raw(load=b"Access Denied"))

sniff(filter="icmp", prn=packet_callback)
```

### Player Solution:
```bash
# Craft Windows-like ICMP packet
hping3 -1 -c 1 -d 32 -t 128 <phantom_ip>
```

## IDS Evasion Patterns

### Pattern 1: Slow ICMP Scan
```bash
# Slow scan to avoid rate-based detection
for ip in $(seq 1 254); do
    ping -c 1 -t 128 192.168.1.$ip
    sleep 2
done
```

### Pattern 2: Mixed TTL Values
```python
# Alternate between OS fingerprints
ttl_rotation = [64, 128, 64, 128]
for i, target in enumerate(target_list):
    ttl = ttl_rotation[i % len(ttl_rotation)]
    send(IP(dst=target, ttl=ttl)/ICMP())
```

## References

- RFC 792: Internet Control Message Protocol
- Scapy documentation: https://scapy.net/
- hping3 manual: http://www.hping.org/
- Nmap OS detection: https://nmap.org/book/osdetect.html

## Lab Integration Ideas

1. **Hop X: PHANTOM** - ICMP fingerprint validation
2. **Hop Y: ICMPWALL** - Firewall that only allows specific TTL ranges
3. **Hop Z: CHAMELEON** - Container that adapts to incoming fingerprint

---

**Note**: This technique is for authorized penetration testing and CTF environments only. Unauthorized use against production systems is illegal.
