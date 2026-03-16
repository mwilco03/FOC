FROM debian:bookworm-slim

RUN rm -f /etc/dpkg/dpkg.cfg.d/docker && \
    apt-get update && apt-get install -y --no-install-recommends \
    shellinabox \
    net-tools \
    iputils-ping \
    dnsutils \
    curl \
    wget \
    netcat-openbsd \
    iproute2 \
    traceroute \
    tcpdump \
    whois \
    vim-tiny \
    nano \
    less \
    jq \
    tmux \
    man-db \
    sudo \
    && apt-get install -y nmap \
    && mandb \
    && rm -rf /var/lib/apt/lists/*

# Copy MOTD, bash notes, and dark theme
COPY motd.txt /etc/motd
COPY bash_notes.txt /opt/bash_notes.txt
COPY shellinabox-dark.css /opt/cyber-dark.css

# Create entrypoint that sets up the team user dynamically
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && sed -i 's/\r$//' /entrypoint.sh

EXPOSE 4200

ENTRYPOINT ["/entrypoint.sh"]
