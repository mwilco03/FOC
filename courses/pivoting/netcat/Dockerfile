# Use as the base image
FROM debian:latest

# Install required packages
RUN apt-get update && apt-get install -y \
    openssh-server \
    curl \
    nmap \
    busybox \
    cadaver \
    davfs2 \
    && rm -rf /var/lib/apt/lists/*

# Create a run directory for OpenSSH
RUN mkdir -p /var/run/sshd
RUN mkdir -p /root/.ssh
COPY pivot_key.pub /root/.ssh/authorized_keys
COPY pivot_key /root/.ssh/id_ed25519

# Copy in our entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose SSH and Netcat listener port
EXPOSE 22 4444

# Use the entrypoint script, which backgrounds sshd and netcat, then tails /dev/null
ENTRYPOINT ["/entrypoint.sh"]
