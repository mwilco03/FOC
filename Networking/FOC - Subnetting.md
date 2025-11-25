# Subnetting Guide

A comprehensive reference for IP addressing, binary conversion, and subnet calculations.

---

## Binary Chart

Understanding binary is fundamental to subnetting. Each bit position represents a power of 2:

| Bit Position | 2⁷ | 2⁶ | 2⁵ | 2⁴ | 2³ | 2² | 2¹ | 2⁰ |
|--------------|----|----|----|----|----|----|----|----|
| **Decimal Value** | **128** | **64** | **32** | **16** | **8** | **4** | **2** | **1** |

**Example:** The number 7 in 4-bit binary is `0111`

Using 8 bits, you can represent any number from 0 to 255.

### IPv4 Address in Binary

| Octet | 1st | 2nd | 3rd | 4th |
|-------|-----|-----|-----|-----|
| **Decimal** | 192 | 168 | 0 | 1 |
| **Binary** | 11000000 | 10101000 | 00000000 | 00000001 |

---

## Hexadecimal Calculation

Hexadecimal uses 16 digits (0-9 and A-F):

| Hex | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | A | B | C | D | E | F |
|-----|---|---|---|---|---|---|---|---|---|---|----|----|----|----|----|----|
| **Dec** | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 |

### Place Values in Hexadecimal

In hex (base 16), place values are powers of 16:

| 16³ | 16² | 16¹ | 16⁰ |
|-----|-----|-----|-----|
| 4096 | 256 | 16 | 1 |

### Example: Convert **3BF2** to Decimal

| Hex Digit | 3 | B | F | 2 |
|-----------|---|---|---|---|
| **Decimal Value** | 3 | 11 | 15 | 2 |
| **Place Value** | 16³ | 16² | 16¹ | 16⁰ |

**Calculation:**
```
3 × 4096 = 12,288
B(11) × 256 = 2,816
F(15) × 16 = 240
2 × 1 = 2
────────────────
Total = 15,346
```

**Result:** `3BF2₁₆ = 15,346₁₀`

### Example: Convert **15,346** to Hexadecimal

Using repeated division by 16:

| Step | Divide by 16 | Quotient | Remainder | Hex Digit |
|------|--------------|----------|-----------|-----------|
| 1 | 15,346 ÷ 16 | 959 | 2 | **2** |
| 2 | 959 ÷ 16 | 59 | 15 | **F** |
| 3 | 59 ÷ 16 | 3 | 11 | **B** |
| 4 | 3 ÷ 16 | 0 | 3 | **3** |

**Read the hex digits in reverse order (bottom to top):** `3BF2`

**Result:** `15,346₁₀ = 3BF2₁₆`

---

## IP Address Classes

| Class | First Octet Range | Default Subnet Mask | CIDR |
|-------|-------------------|---------------------|------|
| **A** | 0 - 127 | 255.0.0.0 | /8 |
| **B** | 128 - 191 | 255.255.0.0 | /16 |
| **C** | 192 - 223 | 255.255.255.0 | /24 |
| **D** | 224 - 239 | (Multicast) | N/A |
| **E** | 240 - 255 | (Reserved) | N/A |

---

## Calculating Subnet Mask

### Example: `10.200.20.0/27`

The `/27` notation means the first 27 bits are the network portion.

| Component | 1st Octet | 2nd Octet | 3rd Octet | 4th Octet | Decimal |
|-----------|-----------|-----------|-----------|-----------|---------|
| **IPv4** | 0000 1010 | 1100 1000 | 0001 0100 | 000**0 0000** | 10.200.20.0 |
| **Subnet Mask** | 1111 1111 | 1111 1111 | 1111 1111 | 111**0 0000** | **255.255.255.224** |
| **Bits** | /8 | /16 | /24 | /32 | |

The `/27` subnet mask equals **255.255.255.224**

---

## Calculating Subnet ID

### Example: `10.200.20.0/27`

**Steps:**
1. Identify the subnet mask: `/27` = `255.255.255.224`
2. Calculate block size: `256 - 224 = 32` (each subnet has 32 IP addresses)
3. List subnet ranges:

| Subnet | Address Range | Broadcast Address |
|--------|---------------|-------------------|
| 10.200.20.0/27 | 10.200.20.0 - 10.200.20.31 | 10.200.20.31 |
| 10.200.20.32/27 | 10.200.20.32 - 10.200.20.63 | 10.200.20.63 |
| 10.200.20.64/27 | 10.200.20.64 - 10.200.20.95 | 10.200.20.95 |

**The Subnet ID is the first address in the range:** `10.200.20.0`

---

## Calculating Broadcast Address

### Example: `10.200.20.0/27`

The broadcast address is found by setting all host bits to 1.

| Component | 1st Octet | 2nd Octet | 3rd Octet | 4th Octet | Decimal |
|-----------|-----------|-----------|-----------|-----------|---------|
| **IPv4** | 0000 1010 | 1100 1000 | 0001 0100 | 000**0 0000** | 10.200.20.0 |
| **Subnet Mask** | 1111 1111 | 1111 1111 | 1111 1111 | 111**0 0000** | 255.255.255.224 |

**Host bits (shown in bold) set to 1:**
- 4th Octet: `000|1 1111` = 31

**Broadcast Address:** `10.200.20.31`

---

## Homework Problems

### Section 1: Binary to Decimal Conversion

| Binary Address | Dotted Decimal |
|----------------|----------------|
| 01101000 11110001 00001101 10110110 | |
| 10100000 11111111 11111110 01011000 | |
| 01111001 00110011 10000001 11100000 | |
| 11110000 11110110 10110001 00110001 | |
| 10101010 00011100 10100110 11100011 | |

### Section 2: Decimal to Binary Conversion

| Dotted Decimal | Binary Address |
|----------------|----------------|
| 188.26.221.100 | |
| 88.91.200.84 | |
| 150.15.60.20 | |
| 222.161.25.10 | |
| 220.10.5.18 | |

### Section 3: Hexadecimal to Decimal Conversion

| Hexadecimal Number | Decimal Equivalent |
|--------------------|-------------------|
| 3BF2 | |
| 468A | |
| C40E | |
| 1D16 | |
| 2EE2 | |

### Section 4: Decimal to Hexadecimal Conversion

| Decimal | Hexadecimal Equivalent |
|---------|------------------------|
| 586 | |
| 5289 | |
| 25840 | |
| 252 | |
| 14732 | |

### Section 5: Subnet Analysis

| IP Address | Subnet Mask | Class | # of Bits for Subnet | Network ID | Subnet ID |
|------------|-------------|-------|----------------------|------------|-----------|
| 188.26.221.100 | 255.255.255.240 | B | 12 | 188.26.0.0 | 188.26.221.96 |
| 128.125.132.191 | 255.255.255.128 | | | | |
| 83.93.100.48 | 255.255.0.0 | | | | |
| 204.158.32.45 | 255.255.255.248 | | | | |
| 132.158.70.30 | 255.255.224.0 | | | | |
| 158.157.68.25 | 255.255.252.0 | | | | |

---

## Example Solutions

### Subnet Analysis: `188.26.221.100/28`

**IP Address:** `188.26.221.100`  
**Subnet Mask:** `255.255.255.240` (/28)

**Analysis:**
- **Class:** B (first octet 128-191)
- **Default Mask:** /16
- **Bits Borrowed:** 28 - 16 = 12 bits
- **Network ID:** 188.26.0.0 (first two octets for Class B)

**Finding Subnet ID using AND method:**

Since the first three octets are all 1s in the subnet mask (255.255.255), they remain unchanged: `188.26.221.?`

For the 4th octet:

| | 128 | 64 | 32 | 16 | 8 | 4 | 2 | 1 |
|---|-----|----|----|----|----|----|----|-----|
| **IP (100)** | 0 | 1 | 1 | 0 | 0 | 1 | 0 | 0 |
| **Mask (240)** | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 |
| **Result (96)** | 0 | 1 | 1 | 0 | 0 | 0 | 0 | 0 |

**Subnet ID:** `188.26.221.96`

---

### Network Design: `172.15.0.0` with 50 Subnets

**Network ID:** `172.15.0.0`  
**Subnet Requests:** 50  
**Class:** B (default mask /16)

**Calculation:**
- 2⁵ = 32 subnets (not enough)
- 2⁶ = 64 subnets ✓
- **Bits borrowed:** 6
- **New CIDR:** /16 + 6 = /22
- **Subnet Mask:** 255.255.252.0

**Block Size:** 256 - 252 = 4 (subnets increment by 4 in 3rd octet)

| Subnet Number | Subnet ID |
|---------------|-----------|
| 1st | 172.15.0.0 |
| 2nd | 172.15.4.0 |
| 3rd | 172.15.8.0 |
| ... | ... |
| Next-to-last | 172.15.248.0 |
| Last | 172.15.252.0 |

---

### Host Range Calculation: `40.50.240.0/20`

**Subnet ID:** `40.50.240.0`  
**Subnet Mask:** /20 = 255.255.240.0  
**Class:** A

**Calculations:**
- Block size: 256 - 240 = 16 (increment by 16 in 3rd octet)
- **First IP:** 40.50.240.1 (subnet ID + 1)
- **Last IP:** 40.50.255.254 (broadcast - 1)
- **Broadcast:** 40.50.255.255

| Component | 1st | 2nd | 3rd | 4th |
|-----------|-----|-----|-----|-----|
| Subnet ID | 40 | 50 | 240 | 0 |
| Subnet Mask | 255 | 255 | 240 | 0 |
| Broadcast | 40 | 50 | 255 | 255 |

---

## Additional Practice Problems

### Section 6: Network Design

| Network ID | Subnet Requests | Class | Subnet Mask | Bits Taken | 2nd Subnet ID | Next-to-Last Subnet ID |
|------------|-----------------|-------|-------------|------------|---------------|------------------------|
| 172.15.0.0 | 50 | B | 255.255.252.0 (/22) | 6 | 172.15.4.0 | 172.15.248.0 |
| 16.0.0.0 | 500 | | | | | |
| 121.0.0.0 | 1000 | | | | | |
| 157.158.0.0 | 20 | | | | | |
| 215.100.10.0 | 16 | | | | | |

### Section 7: Complete Subnet Information

| Subnet ID | Subnet Mask | Class | First IP | Last IP | Broadcast |
|-----------|-------------|-------|----------|---------|-----------|
| 40.50.240.0 | /20 | A | 40.50.240.1 | 40.50.255.254 | 40.50.255.255 |
| 143.30.64.0 | /18 | | | | |
| 220.200.50.96 | /28 | | | | |
| 210.120.50.160 | /27 | | | | |
| 129.100.128.0 | /20 | | | | |

---

## Quick Reference

### Common Subnet Masks

| CIDR | Subnet Mask | Block Size | # of Hosts |
|------|-------------|------------|------------|
| /24 | 255.255.255.0 | 256 | 254 |
| /25 | 255.255.255.128 | 128 | 126 |
| /26 | 255.255.255.192 | 64 | 62 |
| /27 | 255.255.255.224 | 32 | 30 |
| /28 | 255.255.255.240 | 16 | 14 |
| /29 | 255.255.255.248 | 8 | 6 |
| /30 | 255.255.255.252 | 4 | 2 |

### Formulas

- **Number of Subnets:** 2ⁿ (where n = bits borrowed)
- **Number of Hosts per Subnet:** 2ʰ - 2 (where h = host bits)
- **Block Size:** 256 - subnet octet value
- **Broadcast Address:** Last IP in subnet range
- **First Usable IP:** Subnet ID + 1
- **Last Usable IP:** Broadcast Address - 1

---

**Note:** Remember that the subnet ID and broadcast address are not usable for host assignment.
