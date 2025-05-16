# **Simplified troubleshooting checklist**

---

# ✅ Lab Troubleshooting Checklist

> **Objective:** Identify and fix each issue introduced in the broken running-configs to restore full lab functionality.

---

## **1. Disable Port Security Across Switches**

**Devices Affected:** `42-f1-2960`, potentially others
**Symptoms:** Ports in `errdisabled` state, devices not communicating

**Checklist:**

* [ ] Run: `show port-security`
* [ ] Run: `show port-security interface fa0/x`
* [ ] Identify any port in `secure-shutdown`
* [ ] Disable port security:

```bash
conf t
interface range fa0/1 - 24, gi0/1 - 2
 shutdown
 no switchport port-security
 no shutdown
exit
```

---

## **2. Disable Access Lists Blocking Traffic**

**Devices Affected:** `42-f1-3560`
**Symptoms:** Pings blocked, ICMP fails

**Checklist:**

* [ ] Run: `show access-lists` → Look for `deny icmp any any`
* [ ] Run: `show run | include access-group` to see interface bindings
* [ ] Remove access-group from interface:

```bash
conf t
interface gi0/1
 no ip access-group 187 in
exit
no access-list 187
```

---

## **3. Identify EIGRP Neighbor Issues**

**Devices Affected:** `97-f1-3560`
**Symptoms:** Routes missing, no EIGRP neighbors

**Checklist:**

* [ ] Run: `show ip eigrp neighbors` → Should show at least one neighbor
* [ ] Run: `show ip protocols` → Look for correct networks and AS number
* [ ] Fix EIGRP config:

```bash
conf t
router eigrp 100
 network 172.16.0.0 0.0.255.255
exit
```

---

## **4. Identify OSPF Issues**

**Devices Affected:** `42-f2-3560`
**Symptoms:** No OSPF adjacency, incomplete routing

**Checklist:**

* [ ] Run: `show ip ospf neighbor` → Expect `FULL` state
* [ ] Run: `show ip ospf interface` → Verify area and process ID
* [ ] Run: `show ip protocols`
* [ ] Fix OSPF area mismatch:

```bash
conf t
router ospf 1
 network 192.168.0.0 0.0.255.255 area 0
exit
```

---

## **5. Bring Up Down Interfaces**

**Devices Affected:** `97-f1-2960`
**Symptoms:** Interface down, workstation unreachable

**Checklist:**

* [ ] Run: `show ip interface brief` → Look for `administratively down`
* [ ] Bring interface up:

```bash
conf t
interface fa0/6
 no shutdown
exit
```

---

## **6. Identify Missing VLAN Assignments**

**Devices Affected:** `42-f2-2960`
**Symptoms:** Devices not in correct VLAN, no communication

**Checklist:**

* [ ] Run: `show vlan brief` → Missing VLANs or unassigned ports
* [ ] Add VLANs as needed:

```bash
conf t
vlan 130
 name Zone-130
exit
```

* [ ] Assign interfaces to VLAN:

```bash
interface range fa0/3 - 4
 switchport access vlan 130
exit
```

---

## **7. Fix VTP Domain Mismatch**

**Devices Affected:** `AFNET`
**Symptoms:** VLANs not propagating

**Checklist:**

* [ ] Run: `show vtp status` → Look for wrong domain
* [ ] Fix VTP domain and password:

```bash
conf t
vtp domain LAB-VTP
vtp password labpass
vtp mode client
exit
```

---

## **8. Check CDP for Physical Topology Mapping**

(Optional for deeper understanding)

```bash
show cdp neighbors
show cdp neighbors detail
```

---

## ✅ Completion Criteria

You should now have:

* Working routing tables (`show ip route`)
* All interfaces `up/up` (`show ip int brief`)
* Devices in correct VLANs (`show vlan brief`)
* Working pings end-to-end (`ping [destination]`)

---
