#!/bin/bash
# Flag generation script for Pivot Lab
# Generates randomized flags in format: PIVOT{<container>_<random_12_hex>}

set -e

FLAG_DIR="/flags"
mkdir -p "$FLAG_DIR"

generate_flag() {
    local container=$1
    local random_hex=$(openssl rand -hex 6)
    echo "PIVOT{${container}_${random_hex}}"
}

# Generate flags for each hop
echo "Generating flags..."

generate_flag "gate"      > "$FLAG_DIR/flag-01.txt"
generate_flag "tunnel"    > "$FLAG_DIR/flag-02.txt"
generate_flag "fileserv"  > "$FLAG_DIR/flag-03.txt"
generate_flag "webshell"  > "$FLAG_DIR/flag-04.txt"
generate_flag "dropzone"  > "$FLAG_DIR/flag-05.txt"
generate_flag "depot"     > "$FLAG_DIR/flag-06.txt"
generate_flag "resolver"  > "$FLAG_DIR/flag-07.txt"
generate_flag "cache"     > "$FLAG_DIR/flag-08.txt"
generate_flag "vault"     > "$FLAG_DIR/flag-09.txt"

echo "Flags generated successfully!"
ls -lh "$FLAG_DIR"

# Keep container alive briefly to ensure flags are written
sleep 2
