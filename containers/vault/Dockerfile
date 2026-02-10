FROM alpine:3.19

# Hop 9: VAULT
# Services: Samba (445/TCP, 139/TCP), Dovecot IMAP (143/TCP decoy)
# Landing user: (SMB client)
# Points: 1000

RUN apk update && apk add --no-cache \
    bash \
    coreutils \
    openrc \
    samba \
    samba-common-tools \
    dovecot

# Create Samba users
RUN adduser -D -s /bin/bash vaultadmin && \
    echo 'vaultadmin:VaultPass2024!' | chpasswd

# Set Samba password for vaultadmin (same as system password)
RUN (echo 'VaultPass2024!'; echo 'VaultPass2024!') | smbpasswd -a -s vaultadmin

# Create Samba share directories
RUN mkdir -p /srv/samba/public \
             /srv/samba/backup \
             /srv/samba/classified

# Public share (guest accessible)
RUN echo "Welcome to VAULT public share" > /srv/samba/public/README.txt && \
    echo "General information and documentation" >> /srv/samba/public/README.txt

# Backup share (guest accessible - contains shadow.bak with hash)
RUN echo "root:x:0:0:root:/root:/bin/ash" > /srv/samba/backup/shadow.bak && \
    echo "vaultadmin:5f4dcc3b5aa765d61d8327deb882cf99:18000:0:99999:7:::" >> /srv/samba/backup/shadow.bak && \
    echo "# Hash format: MD5" >> /srv/samba/backup/shadow.bak && \
    echo "# Crack this hash to access classified share" >> /srv/samba/backup/shadow.bak

RUN echo "Backup data repository" > /srv/samba/backup/README.txt && \
    echo "Old configuration backups stored here" >> /srv/samba/backup/README.txt

# Classified share (requires authentication)
RUN echo "CLASSIFIED DATA" > /srv/samba/classified/sensitive-docs.txt && \
    echo "Mission-critical information stored here" >> /srv/samba/classified/sensitive-docs.txt

# Set permissions
RUN chmod -R 755 /srv/samba && \
    chown -R vaultadmin:vaultadmin /srv/samba/classified

# Configure Samba
COPY smb.conf /etc/samba/smb.conf

# Configure Dovecot (decoy - empty mailboxes)
RUN mkdir -p /var/mail && \
    touch /etc/dovecot/dovecot.conf

# Setup OpenRC
RUN mkdir -p /run/openrc && \
    touch /run/openrc/softlevel && \
    mkdir -p /var/run/samba

# Create entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 139 445 143

ENTRYPOINT ["/entrypoint.sh"]
