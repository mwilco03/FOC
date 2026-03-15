#!/bin/sh
set -e

# Start SSH in the background (daemon mode)
echo "Starting SSH daemon..."
/usr/sbin/sshd

# Start BusyBox netcat in the background
echo "Starting BusyBox netcat listener on port 4444..."
busybox nc -ll -p 4444 -e /bin/bash &

# Keep container alive indefinitely
echo "All services started. Keeping container alive..."
tail -f /dev/null
