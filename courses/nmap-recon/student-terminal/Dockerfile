FROM debian:bookworm-slim

# --- Build-time constants ----------------------------------------------------
ARG SHELLINABOX_PORT=4200

# --- Install tools: network recon suite + terminal utilities -----------------
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
    libcap2-bin \
    && apt-get install -y nmap \
    && mandb \
    && rm -rf /var/lib/apt/lists/*

# --- Grant raw socket capabilities so tools work without full root -----------
# nmap -sS and tcpdump require cap_net_raw; setcap allows unprivileged use
# for basic scans. SYN scans still require sudo (nmap drops caps internally).
RUN setcap cap_net_raw,cap_net_admin+eip /usr/bin/nmap 2>/dev/null || true && \
    setcap cap_net_raw,cap_net_admin+eip /usr/bin/tcpdump 2>/dev/null || true && \
    setcap cap_net_raw+eip /bin/ping 2>/dev/null || true

# --- Copy static assets ------------------------------------------------------
COPY motd.txt /etc/motd
COPY bash_notes.txt /opt/bash_notes.txt
COPY shellinabox-dark.css /opt/cyber-dark.css

# --- Entrypoint creates users at runtime and starts shellinabox --------------
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && sed -i 's/\r$//' /entrypoint.sh

EXPOSE ${SHELLINABOX_PORT}

ENTRYPOINT ["/entrypoint.sh"]
