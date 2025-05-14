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

## ✅ Final Tips

- Always `do write` after changes.
- Use `interface range` to apply config faster across multiple ports.
- Always clean up ACLs and port security in a lab if they're blocking success.
- Use `cdp` and VLAN tools to visualize paths.
