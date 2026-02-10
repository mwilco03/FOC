# Pivot Lab Documentation

## Core Documentation

- **[Design.md](../Design.md)** - Complete design document v5.0 with architecture, hop walkthroughs, and implementation details
- **[README.md](../README.md)** - Quick start guide and project overview

## Technical References

### ICMP TTL Fingerprinting
- **[ICMP-TTL-FINGERPRINTING.md](ICMP-TTL-FINGERPRINTING.md)** - OS fingerprinting via ICMP TTL/size, crafting false responses, evasion techniques, and potential future hop ideas

## Troubleshooting

### SSH Debug Access

All containers include SSH with a `debug` user for troubleshooting (non-challenge):

```bash
# Access any container for debugging
ssh debug@<container_ip>
# Password: Debug123!
```

**Challenge containers with SSH for debugging:**
- DEPOT (Hop 6)
- RESOLVER (Hop 7)
- VAULT (Hop 9)

**Note**: This SSH access is for lab operators and debugging only, not part of the challenge path.

## Container Architecture

### Universal Services
Every challenge container includes:
- OpenSSH (port 22) - Debug access
- OpenRC - Process supervision
- bash, coreutils - Basic utilities

### Service Patterns

**Active Services**: Started in entrypoint.sh
**Stopped Services**: Installed but not started (e.g., DROPZONE lighttpd)
**Decoy Services**: Running but not vulnerable (e.g., GATE postfix)

## Future Enhancements

### Potential New Hops

1. **PHANTOM (ICMP Evasion)**
   - Only responds to correctly fingerprinted ICMP packets
   - Teaches: OS fingerprinting, packet crafting, evasion
   - Difficulty: Hard

2. **MQTT Hub (IoT Telemetry)**
   - MQTT broker with leaked credentials in telemetry
   - Teaches: IoT protocols, message interception
   - Difficulty: Medium

3. **Git Server (Secret Leakage)**
   - Git-over-HTTP with secrets in commit history
   - Teaches: Version control archaeology, secrets management
   - Difficulty: Medium-Hard

4. **ICMP Tunnel (Covert Channel)**
   - Requires ICMP tunneling for access
   - Teaches: Covert channels, protocol abuse
   - Difficulty: Hard

## Development Notes

### Adding a New Container

1. Create `containers/<name>/Dockerfile`
2. Add services (primary + decoy)
3. Include SSH for troubleshooting
4. Create entrypoint.sh
5. Add to docker-compose.yml
6. Create hint JSON in `hints/`
7. Update breadcrumbs in previous hop

### Hint System

- **Standard Hints**: 3 tiers (10%, 25%, 50% cost)
- **BONUS HINT**: Free after Hop 6 (one-time use)
- Sequential gating: Hop N hints unlock after Hop N-1 completion

### Testing Workflow

```bash
# Build and start
./start.sh

# Access for testing
ssh debug@<container_ip>

# Full reset
./reset.sh
```

---

For questions or contributions, see the main repository.
