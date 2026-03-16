FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Core tools + forensic analysis stack
RUN apt-get update && apt-get install -y --no-install-recommends \
    shellinabox \
    tshark \
    jq \
    yara \
    curl \
    wget \
    netcat-openbsd \
    net-tools \
    iputils-ping \
    iproute2 \
    dnsutils \
    vim-tiny \
    nano \
    less \
    man-db \
    sudo \
    tmux \
    openssh-client \
    ca-certificates \
    gnupg \
    apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# PowerShell Core (for Kansa + PS Remoting to victim VMs)
RUN curl -sSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/microsoft-debian-bookworm-prod bookworm main" > /etc/apt/sources.list.d/microsoft.list && \
    apt-get update && apt-get install -y --no-install-recommends powershell && \
    rm -rf /var/lib/apt/lists/*

# Dark theme for shellinabox
COPY shellinabox-dark.css /opt/cyber-dark.css

# MOTD
COPY motd.txt /etc/motd
RUN sed -i 's/^session.*pam_motd.so.*/# &/' /etc/pam.d/login 2>/dev/null; \
    echo "session optional pam_motd.so motd=/etc/motd noupdate" >> /etc/pam.d/login

# Cheatsheet
COPY bash_notes.txt /opt/bash_notes.txt

# Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 4200

ENTRYPOINT ["/entrypoint.sh"]
