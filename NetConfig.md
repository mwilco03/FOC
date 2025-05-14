# 🛠️ Cisco Packet Tracer Troubleshooting Cheat Sheet (Lab Version)

> ⚠️ **Lab-Only Notice:** This guide is designed for lab environments where removing ACLs and port security is acceptable to achieve connectivity success. **Do not** apply these procedures in production.

---

## 🧭 Navigation

- [Layer 1–2 Preliminary Checks](#layer-1-2-preliminary-checks)
- [Common Lab Resets](#common-lab-resets)
- [Post-Cleanup Verification](#post-cleanup-verification)
- [Advanced Diagnostic Commands](#advanced-diagnostic-commands)
- [Mock Output & Troubleshooting Guide](#mock-output--troubleshooting-guide)
- [Other Lab Essentials](#other-lab-essentials)

---

## 🔌 Layer 1–2 Preliminary Checks

### 🟥 Check Interface Status
```bash
show ip interface brief
```
- `up/up`: Interface working  
- `administratively down`: Use `no shutdown`  
- `down/down`: Physical error or no cable

---

### 🟨 Check Port Security (Common Shutdown Cause)
```bash
show port-security
show port-security interface [interface_id]
```
- `Secure-shutdown`: Port disabled due to MAC violation  
- Violation count > 0: Indicates blocked device

---

## 🔧 Common Lab Resets

### 🚫 Disable Port Security (Lab Use Only)
```bash
conf t
interface range fa0/1 - 24
 shutdown
 no switchport port-security
 no switchport port-security maximum
 no switchport port-security violation
 no switchport port-security mac-address
 no switchport port-security aging
 no switchport port-security sticky
 no shutdown
exit
```

---

### 🚫 Remove ACLs (Lab Use Only)

**Step 1 – Unapply ACLs:**
```bash
conf t
interface [interface_id]
 shutdown
 no ip access-group [ACL# or name] [in|out]
 no shutdown
exit
```

**Step 2 – Remove ACL Definitions:**
```bash
no access-list 101
no ip access-list extended [ACL_NAME]
```

---

## ✅ Post-Cleanup Verification

```bash
show port-security                      # Ensure ports are not shut down
show access-lists                       # Confirm ACLs removed
show run | include access-group         # Check for applied ACLs
show ip interface brief                 # Confirm interface status
show interfaces status                  # Check port status and errors
```

---

## 🔄 Optional: Auto-Recover from Port Security Errors

```bash
conf t
errdisable recovery cause psecure-violation
errdisable recovery interval 30
do write
```

---

## 🧠 Other Lab Essentials

### 🔒 Enable SSH for Device Access
```bash
conf t
line vty 0 4
transport input ssh
login local
exit
username netadmin privilege 15 secret warrior
do write
```

---

### 🌍 Around-the-World Ping Test
```bash
ping 172.16.255.2   # L3 Switch <-> RTR-Z1-Local
ping 172.16.255.1   # RTR-Z1-Local
ping 172.31.0.2     # RTR-Z1-Local <-> RTR-ZX-External
ping 172.31.0.1     # RTR-ZX-External
```

---

### 📋 Configure L3 Switch Interface
```bash
conf t
interface gi0/1
no switchport
ip address 172.16.255.2 255.255.255.252
no shutdown
do write
```

---

### 📡 Use Sniffer to Monitor DHCP Traffic

#### Setup:
- Add a **Sniffer** device
- Connect it to same switch as DHCP client/server
- Use **Simulation Mode**
- Filter for **DHCP** only

#### Event Types to Capture:
- `DHCP Discover`, `DHCP Offer`, `DHCP Request`, `DHCP ACK`

#### Verifying DHCP Function:
```bash
show ip int brief
show vlan brief
show interfaces trunk
```

---

## 🧪 Advanced Diagnostic Commands

```bash
# VLAN & Trunking
show vlan brief
show interfaces trunk

# VTP
show vtp status
show vtp password

# Port Security
show port-security
show port-security interface [int]

# ACLs
show access-lists
show run | include access-group

# Routing Protocols
show ip protocols
show ip ospf neighbor
show ip ospf interface
show ip eigrp neighbors
show ip eigrp topology

# Interface & Log Checks
show interfaces status
show logging
```

---

# 🧪 Mock Output & Troubleshooting Guide

---

## 🔹 VLAN & Trunking

### `show vlan brief`
```plaintext
130  User-Z1                          active    Fa0/1, Fa0/2
```
✅ Ports must be in correct VLANs  
❌ Ports in VLAN 1 = default/misconfigured

---

### `show interfaces trunk`
```plaintext
Fa0/1       on   802.1q   trunking    5
Allowed VLANs: 5,130-135
```
✅ Trunks must include all used VLANs  
❌ Mismatched VLANs = broken inter-VLAN routing

---

## 🔹 VTP

### `show vtp status`
```plaintext
VTP Domain Name: LAB-VTP
VTP Mode: Client
VTP Password: ***
```
✅ All switches must match domain/mode/password  
❌ Transparent mode won't sync VLANs

---

### `show vtp password`
```plaintext
VTP password: labpass
```

---

## 🔹 Port Security

### `show port-security`
```plaintext
Fa0/3   Enabled   1 violation   secure-shutdown
```
✅ Max MACs = 2+, or remove  
❌ `secure-shutdown` needs interface reset

---

## 🔹 ACLs

### `show access-lists`
```plaintext
Extended IP access list 187
  deny icmp any any
  permit ip any any
```
❌ `deny icmp` blocks pings

---

### `show run | include access-group`
```plaintext
ip access-group 187 in
```
✅ Use to locate interface where ACL is applied

---

## 🔹 Routing (OSPF & EIGRP)
> 💡 Tip: If a static route exists to the same destination, it will override dynamic routes. 
> Use `show ip route` to check if a static route is the reason a dynamic one isn’t being used.

### `show ip protocols`
```plaintext
Routing Protocol is "eigrp 100"
  Networks: 192.168.10.0, 172.16.0.0
```
✅ All internal networks must be included

---

### `show ip ospf neighbor`
```plaintext
Neighbor ID   State    Interface
192.168.1.1   FULL     Fa0/1
```
✅ Must be in FULL or 2WAY  
❌ DEAD timer = adjacency failed

---

### `show ip ospf interface`
```plaintext
Fa0/1 is up, Area 0, Router ID 1.1.1.1
```

---

### `show ip eigrp neighbors`
```plaintext
172.16.1.2   Fa0/1   00:02:31
```

---

### `show ip eigrp topology`
```plaintext
P 192.168.10.0/24, FD 3072
 via 172.16.1.2 (3072/2816), Fa0/1
```
✅ “P” = passive (good)  
❌ “A” = active (route unresolved)

---

## 🔹 Interface & Log Checks

### `show interfaces status`
```plaintext
Fa0/1   connected   VLAN 130   a-full  a-100
Fa0/2   notconnect
```

---

### `show logging`
```plaintext
%PORT_SECURITY-2-PSECURE_VIOLATION
%LINK-3-UPDOWN
```
✅ Indicates port security triggers or cable re-plugs

---

## 🔹 Device Connectivity & Topology (CDP)

### `show cdp neighbors`
```plaintext
Device ID        Local Intrfce     Holdtme    Capability  Platform  Port ID
SW-Z2-Core       Fa0/1             131           S I      3560      Fa0/24
RTR-Z1-Local     Fa0/2             129           R S I    2811      Gi0/0
```
✅ Shows which devices are connected to which interfaces  
❌ No entries = cable missing, CDP disabled, or interface down

---

### `show cdp neighbors detail`
```plaintext
Device ID: RTR-Z1-Local
IP address: 172.16.255.1
Platform: cisco 2811, Capabilities: Router Switch IGMP
Interface: FastEthernet0/2, Port ID (outgoing port): GigabitEthernet0/0
```
✅ Helps verify routing neighbor IPs  
✅ Useful for identifying uplinks or finding default gateway IPs

---

## 📍 Static Route Troubleshooting

### 🔹 `show ip route`

```plaintext
S    192.168.10.0/24 [1/0] via 172.16.0.1
D    192.168.10.0/24 [90/3072] via 172.16.0.2
````

✅ `S` = Static route (AD 1), will be preferred over EIGRP (`D`, AD 90)

### 🔍 What to Look For:

* Static routes overriding dynamic ones?
* Conflicting entries? (e.g., two routes to the same network with different sources)

---

### 🔹 `show run | include ip route`

```plaintext
ip route 192.168.10.0 255.255.255.0 172.16.0.1
```

✅ Check static routes configured manually

---

### 💡 Common Fixes:

* **Remove static route** if it’s interfering with dynamic:

```bash
no ip route 192.168.10.0 255.255.255.0 172.16.0.1
```

* Or **change administrative distance** (optional):

```bash
ip route 192.168.10.0 255.255.255.0 172.16.0.1 5
```

---

### 🧪 Static + Dynamic Route Coexistence Example

```plaintext
S    10.10.0.0/16 [1/0] via 172.16.0.1
D    10.10.0.0/16 [90/3072] via 172.16.0.2
````

✅ This shows the static route taking precedence.
Use `show ip route` to confirm which path is active.

### 🧠 Notes:

* **Static routes are not visible via routing protocols**
* **AD determines which route is installed**, not who advertised it

## ✅ Final Tips

- `do write` after all changes
- Use `interface range` to clean configs faster
- Use `cdp` and VLAN maps to trace connectivity
- Reset ACLs and port security first when troubleshooting lab pings
