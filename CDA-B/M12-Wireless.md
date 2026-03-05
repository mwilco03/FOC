**Lesson-by-lesson breakdown of Module 12 – Wireless Networking**
---

## Module 12 – Wireless Networking

---

## Lesson 1: Wi-Fi Standards (IEEE 802.11)

### Key Concepts

* Wireless LANs (WLANs) use radio frequencies to transmit data
* Governed by the **IEEE 802.11** family of standards
* Two frequency bands: **2.4 GHz** (longer range, more interference) and **5 GHz** (shorter range, faster)
* Wi-Fi 6E introduces **6 GHz** band

### 802.11 Standards Comparison

| Standard | Wi-Fi Name | Frequency | Max Speed | Year | Notes |
|----------|-----------|-----------|-----------|------|-------|
| 802.11a | — | 5 GHz | 54 Mbps | 1999 | First 5 GHz standard |
| 802.11b | — | 2.4 GHz | 11 Mbps | 1999 | First widely adopted |
| 802.11g | — | 2.4 GHz | 54 Mbps | 2003 | Backward compatible with b |
| 802.11n | Wi-Fi 4 | 2.4/5 GHz | 600 Mbps | 2009 | MIMO, channel bonding |
| 802.11ac | Wi-Fi 5 | 5 GHz | 6.9 Gbps | 2013 | MU-MIMO, beamforming |
| 802.11ax | Wi-Fi 6/6E | 2.4/5/6 GHz | 9.6 Gbps | 2019 | OFDMA, BSS coloring, TWT |

### Key Technologies

| Technology | Description |
|------------|-------------|
| **MIMO** | Multiple Input Multiple Output — multiple antennas for parallel streams |
| **MU-MIMO** | Multi-User MIMO — serves multiple clients simultaneously |
| **OFDMA** | Orthogonal Frequency Division Multiple Access — divides channel into sub-carriers |
| **Beamforming** | Focuses signal toward specific clients |
| **Channel Bonding** | Combines adjacent channels for higher throughput |
| **TWT** | Target Wake Time — improves IoT battery life (Wi-Fi 6) |

### 2.4 GHz vs 5 GHz

| Property | 2.4 GHz | 5 GHz |
|----------|---------|-------|
| Range | Longer (better wall penetration) | Shorter |
| Speed | Lower | Higher |
| Channels | 3 non-overlapping (1, 6, 11) | 24 non-overlapping |
| Interference | High (microwaves, Bluetooth) | Low |
| Best For | IoT devices, range priority | Streaming, gaming, density |

---

## Lesson 2: WLAN Architecture

### Key Concepts

* WLANs consist of Access Points (APs), Wireless LAN Controllers (WLCs), and client devices
* Two deployment models: **Autonomous** (standalone APs) and **Lightweight** (controller-based)

### WLAN Components

| Component | Role |
|-----------|------|
| **Access Point (AP)** | Bridges wireless clients to wired network |
| **WLC (Wireless LAN Controller)** | Centrally manages multiple APs |
| **SSID** | Service Set Identifier — the network name |
| **BSS** | Basic Service Set — single AP and its clients |
| **ESS** | Extended Service Set — multiple APs with same SSID (roaming) |
| **BSSID** | MAC address of the AP radio |

### Autonomous vs Lightweight APs

| Feature | Autonomous AP | Lightweight AP (CAPWAP) |
|---------|--------------|------------------------|
| Management | Individual configuration | Centrally managed by WLC |
| Firmware | Full IOS | Thin — WLC handles logic |
| Scalability | Low (manual config each) | High (WLC manages hundreds) |
| Protocol | N/A | CAPWAP (UDP 5246/5247) |
| Use Case | Small office, home | Enterprise |

### CAPWAP (Control And Provisioning of Wireless Access Points)

* **Control Plane**: UDP 5246 — management, configuration
* **Data Plane**: UDP 5247 — encapsulated client traffic
* Tunnel between AP and WLC allows centralized policy enforcement

### Cisco WLC Configuration

```
! Basic WLAN setup on WLC
wlan OFFICE_WIFI 1 OFFICE_WIFI
  client vlan 10
  no shutdown
  security wpa akm dot1x
  security wpa wpa2 ciphers aes
```

---

## Lesson 3: Wireless Security

### Key Concepts

* Wireless signals extend beyond physical boundaries — security is critical
* Evolution: WEP → WPA → WPA2 → WPA3

### Security Protocol Comparison

| Protocol | Encryption | Key Management | Status |
|----------|-----------|---------------|--------|
| **WEP** | RC4 (64/128-bit) | Static shared key | **Broken** — never use |
| **WPA** | TKIP (RC4-based) | Per-packet key mixing | **Deprecated** — avoid |
| **WPA2** | AES-CCMP (128-bit) | 4-way handshake | **Current standard** |
| **WPA3** | AES-GCMP (192/256-bit) | SAE (Simultaneous Authentication of Equals) | **Latest** — recommended |

### WPA2 Authentication Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| **WPA2-Personal (PSK)** | Pre-Shared Key — same password for everyone | Home, small office |
| **WPA2-Enterprise (802.1X)** | Individual credentials via RADIUS server | Corporate environments |

### WPA3 Improvements Over WPA2

* **SAE Handshake**: Replaces PSK 4-way handshake — resistant to offline dictionary attacks
* **Forward Secrecy**: Compromising one session key doesn't expose past sessions
* **Protected Management Frames**: Mandatory (optional in WPA2)
* **192-bit Security Suite**: For government/sensitive environments

### 802.1X / EAP Framework

```
Client (Supplicant) ←→ AP (Authenticator) ←→ RADIUS Server (Auth Server)
```

| EAP Method | Description |
|------------|-------------|
| **EAP-TLS** | Certificate on both client and server — most secure |
| **PEAP** | Server certificate + client password (MSCHAPv2) |
| **EAP-FAST** | Cisco proprietary — PAC-based, no PKI needed |

### Wireless Attacks and Mitigations

| Attack | Description | Mitigation |
|--------|-------------|------------|
| **Evil Twin** | Rogue AP impersonating legitimate SSID | 802.1X, WIDS/WIPS, client cert validation |
| **Deauthentication** | Forged deauth frames disconnect clients | WPA3 Protected Management Frames (PMF) |
| **WPS Brute Force** | PIN-based WPS is guessable | Disable WPS |
| **KRACK** | Key Reinstallation Attack on WPA2 | Patch firmware, use WPA3 |
| **Wardriving** | Scanning for open/weak networks | Strong encryption, hide SSID (limited), MAC filtering (limited) |

---

## Lesson 4: Wireless Troubleshooting

### Common Wireless Issues

| Issue | Symptoms | Resolution |
|-------|----------|------------|
| **Co-channel interference** | Slow speeds in dense areas | Use non-overlapping channels (1, 6, 11) |
| **Adjacent channel interference** | Intermittent drops | Increase channel separation |
| **Low signal strength** | Client can't connect or disconnects | Adjust AP placement, increase power, add APs |
| **DHCP exhaustion** | Clients get APIPA (169.254.x.x) | Increase DHCP scope, reduce lease time |
| **Authentication failures** | "Can't connect" with correct password | Verify RADIUS, check certificates, check NTP |

### Diagnostic Commands

```bash
# Windows
netsh wlan show interfaces         # Current connection details
netsh wlan show networks mode=bssid  # Scan available networks
netsh wlan show drivers            # Wi-Fi adapter capabilities

# Linux
iwconfig                           # Wireless interface info
iw dev wlan0 scan                  # Scan for networks
nmcli device wifi list             # Available Wi-Fi networks
wavemon                            # Real-time signal monitoring

# Cisco WLC
show wlan summary                  # List configured WLANs
show ap summary                    # List managed APs
show client summary                # Connected clients
debug capwap events enable         # CAPWAP troubleshooting
```

### Site Survey Concepts

* **Heat Map**: Visual representation of signal strength across a floor plan
* **Signal-to-Noise Ratio (SNR)**: Higher is better — aim for > 25 dB
* **RSSI**: Received Signal Strength Indicator — aim for > -65 dBm for reliable connectivity
* **Channel Planning**: Assign non-overlapping channels to adjacent APs

---

## Summary of Wireless Standards and Security

| Standard | Security | Band | Key Feature |
|----------|----------|------|-------------|
| 802.11n (Wi-Fi 4) | WPA2 | 2.4/5 GHz | MIMO |
| 802.11ac (Wi-Fi 5) | WPA2 | 5 GHz | MU-MIMO, beamforming |
| 802.11ax (Wi-Fi 6) | WPA3 | 2.4/5/6 GHz | OFDMA, TWT |

---

## Module 12 Objectives Covered

| Objective | Met By |
|-----------|--------|
| Identify 802.11 standards and their capabilities | Standards comparison table + key technologies |
| Understand WLAN architecture components | AP, WLC, BSS/ESS, CAPWAP explanation |
| Compare wireless security protocols | WEP → WPA → WPA2 → WPA3 evolution |
| Distinguish WPA2-Personal vs Enterprise | PSK vs 802.1X/RADIUS comparison |
| Recognize wireless attacks and mitigations | Attack table with countermeasures |
| Troubleshoot common wireless issues | Diagnostic commands and resolution steps |
