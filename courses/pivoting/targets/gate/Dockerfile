FROM alpine:3.19

# Hop 1: GATE
# Services: ncat (9999/TCP), OpenSSH (22/TCP), Postfix SMTP (25/TCP decoy)
# Landing user: ctf
# Points: 100

RUN apk update && apk add --no-cache \
    bash \
    coreutils \
    openrc \
    nmap-ncat \
    openssh \
    postfix

# Create ctf user
RUN adduser -D -s /bin/bash ctf && \
    echo 'ctf:ctf' | chpasswd

# Create user home structure
RUN mkdir -p /home/ctf/.ssh /home/ctf/.notes && \
    chmod 700 /home/ctf/.ssh

# Create persistence documentation
RUN echo "SSH Key Persistence Guide" > /home/ctf/PERSISTENCE.txt && \
    echo "" >> /home/ctf/PERSISTENCE.txt && \
    echo "To maintain access to this container:" >> /home/ctf/PERSISTENCE.txt && \
    echo "1. Generate SSH key on LAUNCHPAD: ssh-keygen -t ed25519 -f ~/.ssh/pivot_key -N \"\"" >> /home/ctf/PERSISTENCE.txt && \
    echo "2. Copy the public key content" >> /home/ctf/PERSISTENCE.txt && \
    echo "3. On this container: mkdir -p ~/.ssh && echo '<pubkey>' >> ~/.ssh/authorized_keys" >> /home/ctf/PERSISTENCE.txt && \
    echo "4. Set permissions: chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys" >> /home/ctf/PERSISTENCE.txt && \
    echo "5. Connect: ssh -i ~/.ssh/pivot_key ctf@<gate_ip>" >> /home/ctf/PERSISTENCE.txt

# Create tools directory with static binaries (placeholders - to be mounted)
RUN mkdir -p /tools && \
    echo "Static tools for network traversal" > /tools/README.txt

# Credential breadcrumb for TUNNEL
RUN mkdir -p /home/ctf/.notes && \
    echo "# TUNNEL access" > /home/ctf/.notes/credentials.bak && \
    echo "operator:SecureOp2024!" >> /home/ctf/.notes/credentials.bak && \
    chmod 644 /home/ctf/.notes/credentials.bak

RUN chown -R ctf:ctf /home/ctf

# Configure OpenSSH
RUN ssh-keygen -A && \
    mkdir -p /run/openrc && \
    touch /run/openrc/softlevel

# Configure Postfix (decoy - minimal config)
RUN newaliases

# Create entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY ncat-banner.sh /usr/local/bin/ncat-banner.sh
RUN chmod +x /usr/local/bin/ncat-banner.sh

EXPOSE 22 25 9999

ENTRYPOINT ["/entrypoint.sh"]
