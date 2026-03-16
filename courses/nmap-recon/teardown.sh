#!/bin/bash
# Tear down the entire lab and clean up volumes
cd "$(dirname "$0")"
echo "[!] This will stop all containers and delete CTFd data."
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker compose down -v
    echo "[+] Lab torn down."
else
    echo "[-] Cancelled."
fi
