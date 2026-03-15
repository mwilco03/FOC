═══════════════════════════════════════════════════════════════
                      TOOLS DIRECTORY
              Static Binaries for Network Traversal
═══════════════════════════════════════════════════════════════

This directory contains statically-compiled network tools that can
be transferred to target containers.

Available tools:
- ncat-static:   Netcat for listeners and connections
- socat-static:  Bidirectional relay and tunneling
- chisel:        SOCKS proxy and multi-hop tunnels

These tools are mounted read-only on LAUNCHPAD and GATE.

Usage:
1. Transfer tools to target containers using file transfer techniques
   (ncat pipe, base64, busybox httpd, etc.)
2. Make executable: chmod +x <tool>
3. Use as needed for your operations

Note: Tools are statically compiled to work on minimal Alpine Linux
containers without dependencies.

For most operations, try to use built-in utilities first (bash, curl,
ssh) before transferring these tools. Living off the land is preferred.

═══════════════════════════════════════════════════════════════
