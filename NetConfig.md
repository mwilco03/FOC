# 🛠️ Cisco Packet Tracer Troubleshooting Cheat Sheet (Lab Version)

> ⚠️ **Lab-Only Notice:** In this lab context, disabling port security and ACLs is acceptable to ensure successful connectivity. Do **not** apply these steps in production networks.

---

## ✅ Preliminary Checks (Layer 1-2)

### 🟥 Identify "Down'd" Interface
```bash
show ip interface brief
```
- `up/up`: Interface working correctly  
- `administratively down`: Use `no shutdown`  
- `down/down`: Cabling issue or port error

---

### 🟨 Port Security Violation (e.g., SW-Z2-Access)
```bash
show port-security
show port-security interface [interface_id]
```
- `Secure-shutdown` = port disabled  
- Violation count > 0 → see below for full reset

---

## 🧪 Advanced Diagnostic Commands

```bash
show vlan brief                          # VLAN-to-port mapping
show interfaces trunk                   # Trunking status and allowed VLANs
show vtp status                         # VTP domain and mode
show vtp password                       # VTP password match
show port-security                      # View port security on all interfaces
show access-lists                       # View defined ACLs
show run | include access-group         # View where ACLs are applied
show ip protocols                       # Shows OSPF/EIGRP summary
show ip ospf neighbor                   # OSPF adjacents
show ip ospf interface                  # OSPF interface details
show ip eigrp neighbors                 # EIGRP adjacents
show ip eigrp topology                  # EIGRP learned routes
show interfaces status                  # Port connection and errors
show logging                            # Log buffer for errors/events (if used)
```

---

## 🔧 Reset Port Security (Lab-Only Reset)

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

- Removes all port security constraints from access ports

---

## 🔧 Remove ACLs (Lab-Only Reset)

### Step 1: Unapply ACLs from Interfaces
```bash
conf t
interface [interface_id]
 shutdown
 no ip access-group [ACL# or name] [in|out]
 no shutdown
exit
```

### Step 2: Remove ACL Definitions
```bash
no access-list 101
no ip access-list extended [ACL_NAME]
```

- Removes named or numbered ACLs entirely

---

## 🔁 Post-Cleanup Verification

```bash
show port-security                      # Confirm no ports are secure-shutdown
show access-lists                       # Ensure ACLs removed
show run | include access-group         # Ensure no interfaces have ACLs applied
show ip interface brief                 # Interfaces up
show interfaces status                  # Verify connected/disconnected state
```

---

## 🧠 Optional (Recommended): Auto-Recover from Port Security Errors

```bash
conf t
errdisable recovery cause psecure-violation
errdisable recovery interval 30
do write
```

- Automatically brings ports back online after a violation in 30 seconds

---

## 🔁 Around-the-World Ping Test

```bash
ping 172.16.255.2   # L3 Switch <-> RTR-Z1-Local
ping 172.16.255.1   # RTR-Z1-Local
ping 172.31.0.2     # RTR-Z1-Local <-> RTR-ZX-External
ping 172.31.0.1     # RTR-ZX-External
```

Use to trace connection path and locate routing failures.

---

## 🔒 SSH Access (SW-Z1-Core)

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

## 📋 Layer 3 Switch Configuration (Enable Routing)

```bash
conf t
interface gi0/1
no switchport
ip address 172.16.255.2 255.255.255.252
no shutdown
do write
```

---
### 🧪 Use Packet Tracer Sniffer to Monitor DHCP Traffic

> Cisco Packet Tracer includes a Sniffer device that can be used to filter for DHCP traffic (lab task: monitor on SW-Z2-Access).

#### ✅ Setup Steps

1. **Open End Devices** or **Simulation Tools**
2. Drag and drop the **Sniffer** device into the topology
3. Connect the Sniffer to the same switch (e.g., `SW-Z2-Access`) using a **copper straight-through cable**
4. Ensure the Sniffer is on the **same VLAN or trunk port** as the client or DHCP server

#### 🧪 Configure Filters in Simulation Mode

1. Switch to **Simulation Mode**
2. Set **Event List Filters**:
   - ✅ Enable **DHCP**
   - Optionally: disable other protocols (ICMP, ARP, etc.)

#### 🔍 What to Look For

Watch for these DHCP packets in the Event List:
- `DHCP Discover` (from client)
- `DHCP Offer` (from server)
- `DHCP Request` (from client)
- `DHCP ACK` (from server)

If packets do **not appear**:
- Ensure client is set to DHCP
- Ensure VLAN and trunking are correctly configured
- Ensure DHCP server or helper address is present

#### ✅ Useful Verification Commands

```bash
show ip int brief         # Check if IP was assigned via DHCP
show vlan brief           # VLAN matches for server/client
show interfaces trunk     # Ensure VLAN allowed on uplinks
```
---
## ✅ Final Tips

- Always `do write` after changes.
- Use `interface range` to apply config faster across multiple ports.
- Always clean up ACLs and port security in a lab if they're blocking success.
- Use `cdp` and VLAN tools to visualize paths.

---
# 🧪 Advanced Diagnostic Commands – Mock Output and What to Look For

---

### 🔹 `show vlan brief`

**Mock Output:**
```plaintext
VLAN Name                             Status    Ports
---- -------------------------------- --------- -------------------------------
1    default                          active    Fa0/19, Fa0/20
5    Native                           active    
130  User-Z1                          active    Fa0/1, Fa0/2
131  User-Z2                          active    Fa0/3
132  VoIP-Z2                          active    
```

**Look For:**
- Are all required VLANs present?
- Are the access ports assigned correctly?

**Common Issues:**
- Ports stuck in VLAN 1 (default)
- VLAN not created but referenced elsewhere
- Host ports not assigned to any VLAN

---

### 🔹 `show interfaces trunk`

**Mock Output:**
```plaintext
Port        Mode         Encapsulation  Status        Native vlan
Fa0/1       on           802.1q         trunking      5

Port        Vlans allowed on trunk
Fa0/1       5,130-135
```

**Look For:**
- Trunks must allow VLANs used by hosts
- Native VLAN must match on both ends

**Common Issues:**
- VLAN used by client not allowed on trunk
- Native VLAN mismatches between switches

---

### 🔹 `show vtp status`

**Mock Output:**
```plaintext
VTP Version                     : 2
Configuration Revision          : 5
Maximum VLANs supported locally: 255
Number of existing VLANs       : 7
VTP Operating Mode              : Client
VTP Domain Name                 : LAB-VTP
VTP Password                   : ***

```

**Look For:**
- All switches must share same **domain**, **mode**, and **password**
- Revision should increment with updates from the server

**Common Issues:**
- Missing VTP password
- Wrong domain name or transparent mode

---

### 🔹 `show vtp password`

**Mock Output:**
```plaintext
VTP password: labpass
```

**Look For:**
- Should match across all switches in same domain

**Common Issues:**
- Not configured → no VLAN propagation

---

### 🔹 `show port-security`

**Mock Output:**
```plaintext
Port    Security   Violations  Secure MACs  Status
Fa0/3   Enabled     1           1            secure-shutdown
Fa0/4   Enabled     0           1            secure-up
```

**Look For:**
- Ports in `secure-shutdown` are disabled due to violations
- Violation count > 0 indicates dropped or blocked devices

**Common Issues:**
- Max MAC = 1 causes unnecessary shutdowns
- No sticky MAC configured

---

### 🔹 `show access-lists`

**Mock Output:**
```plaintext
Standard IP access list 10
    10 permit 192.168.1.0, wildcard bits 0.0.0.255

Extended IP access list 187
    10 deny icmp any any
    20 permit ip any any
```

**Look For:**
- `deny icmp` blocks ping = trouble for connectivity tests

**Common Issues:**
- Overly broad denies (e.g., `deny ip any any`)
- ACL applied on wrong interface or in wrong direction

---

### 🔹 `show run | include access-group`

**Mock Output:**
```plaintext
 ip access-group 187 in
```

**Look For:**
- Where ACLs are applied (interface and direction)
- Should be removed for lab connectivity

---

### 🔹 `show ip protocols`

**Mock Output (EIGRP):**
```plaintext
Routing Protocol is "eigrp 100"
  Automatic network summarization is not in effect
  Routing for Networks:
    192.168.10.0
    172.16.0.0
```

**Look For:**
- All subnets must be included under `network` commands
- Correct AS number used (e.g., `eigrp 100`)

**Common Issues:**
- Subnets missing from routing advertisements
- Wrong or mismatched AS numbers

---

### 🔹 `show ip ospf neighbor`

**Mock Output:**
```plaintext
Neighbor ID     Pri   State           Dead Time   Address         Interface
192.168.1.1      1    FULL/DR         00:00:38    172.16.0.2      Fa0/1
```

**Look For:**
- At least one neighbor in `FULL` or `2WAY` state

**Common Issues:**
- Dead timer expiry (wrong timers)
- No adjacency (area mismatch, IP mismatch)

---

### 🔹 `show ip ospf interface`

**Mock Output:**
```plaintext
FastEthernet0/1 is up, line protocol is up
  Internet Address 172.16.0.1/30, Area 0
  Process ID 1, Router ID 1.1.1.1, Network Type BROADCAST
```

**Look For:**
- Area number consistency
- Correct OSPF process ID and IP

---

### 🔹 `show ip eigrp neighbors`

**Mock Output:**
```plaintext
Address          Interface       Holdtime  Uptime    SRTT  RTO  Q  Seq
172.16.1.2       Fa0/1           12        00:02:31  30    180  0  15
```

**Look For:**
- Neighbors listed (means EIGRP adjacency formed)

**Common Issues:**
- No entries = misconfigured network statements or interfaces down

---

### 🔹 `show ip eigrp topology`

**Mock Output:**
```plaintext
P 192.168.10.0/24, 1 successors, FD is 3072
        via 172.16.1.2 (3072/2816), FastEthernet0/1
```

**Look For:**
- Routes learned from neighbors
- “P” = passive (good), “A” = active (bad)

---

### 🔹 `show interfaces status`

**Mock Output:**
```plaintext
Port      Name               Status       Vlan       Duplex  Speed Type
Fa0/1                         connected    130        a-full  a-100 10/100BaseTX
Fa0/2                         notconnect   130        auto    auto  10/100BaseTX
```

**Look For:**
- Connected status for active ports
- Duplex/speed mismatches may cause errors

---

### 🔹 `show logging`

**Mock Output:**
```plaintext
%LINK-3-UPDOWN: Interface FastEthernet0/3, changed state to up
%PORT_SECURITY-2-PSECURE_VIOLATION: Security violation occurred...
```

**Look For:**
- Logs of security violations or port state changes

**Common Issues:**
- Frequent port shutdowns = excessive violations

---

