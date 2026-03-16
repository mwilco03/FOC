# Attack PCAP

Place `attack.pcap` in this directory before deploying.

## Option 1: Download a real-world sample
Browse https://www.malware-traffic-analysis.net/ for samples with:
- DNS C2 beaconing (regular interval queries)
- SMB lateral movement
- HTTP/HTTPS C2

Then recolor IPs with tcprewrite:
```bash
tcprewrite --infile=original.pcap --outfile=attack.pcap \
  --srcipmap=OLD_VICTIM_IP:172.20.1.50 \
  --dstipmap=OLD_C2_IP:203.0.113.99
```

## Option 2: Generate synthetic PCAP
```bash
# Coming soon: python3 generate_pcap.py
```

## Recommended samples
- Redline Stealer with DNS C2 (2024 samples on malware-traffic-analysis.net)
- Any sample with PCAP showing DNS beaconing + lateral movement
- CICIDS-2017 dataset (https://www.unb.ca/cic/datasets/ids-2017.html)
