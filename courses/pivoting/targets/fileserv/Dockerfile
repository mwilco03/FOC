FROM alpine:3.19

# Hop 3: FILESERV
# Services: vsftpd (21/TCP, anonymous), MariaDB (3306/TCP decoy)
# Landing user: (FTP only)
# Points: 200

RUN apk update && apk add --no-cache \
    bash \
    coreutils \
    openrc \
    vsftpd \
    mariadb \
    mariadb-client

# Configure vsftpd for anonymous access
RUN mkdir -p /srv/ftp/pub/backups && \
    mkdir -p /var/run/vsftpd/empty

# Create FTP data files (loot)
RUN echo "#!/bin/bash" > /srv/ftp/pub/deploy.sh && \
    echo "# DROPZONE deployment script" >> /srv/ftp/pub/deploy.sh && \
    echo "# Credentials for SSH access:" >> /srv/ftp/pub/deploy.sh && \
    echo "# User: deployer" >> /srv/ftp/pub/deploy.sh && \
    echo "# Pass: D3pl0y2024Secure" >> /srv/ftp/pub/deploy.sh

RUN echo "# Onboarding Notes" > /srv/ftp/pub/onboarding-notes.txt && \
    echo "" >> /srv/ftp/pub/onboarding-notes.txt && \
    echo "Important service notes:" >> /srv/ftp/pub/onboarding-notes.txt && \
    echo "- Redis on CACHE has no password set (TODO: fix this!)" >> /srv/ftp/pub/onboarding-notes.txt && \
    echo "- Default port 6379" >> /srv/ftp/pub/onboarding-notes.txt && \
    echo "- All operators have SSH access to Redis container" >> /srv/ftp/pub/onboarding-notes.txt

RUN echo "# WebDAV Setup" > /srv/ftp/pub/webdav-setup.txt && \
    echo "" >> /srv/ftp/pub/webdav-setup.txt && \
    echo "WebDAV has been installed on DROPZONE for file operations" >> /srv/ftp/pub/webdav-setup.txt && \
    echo "Note: Service is installed but NOT started by default" >> /srv/ftp/pub/webdav-setup.txt && \
    echo "Use: sudo rc-service lighttpd start" >> /srv/ftp/pub/webdav-setup.txt

RUN echo "# TFTP Notes" > /srv/ftp/pub/tftp-notes.txt && \
    echo "" >> /srv/ftp/pub/tftp-notes.txt && \
    echo "TFTP server running on DEPOT" >> /srv/ftp/pub/tftp-notes.txt && \
    echo "Port: 69/UDP (note: UDP, not TCP!)" >> /srv/ftp/pub/tftp-notes.txt && \
    echo "No authentication required" >> /srv/ftp/pub/tftp-notes.txt && \
    echo "Config backups are stored there" >> /srv/ftp/pub/tftp-notes.txt

# Create webapp backup with upload vulnerability hint
RUN mkdir -p /tmp/webapp-backup && \
    echo "<?php" > /tmp/webapp-backup/upload.php && \
    echo "// File upload handler" >> /tmp/webapp-backup/upload.php && \
    echo "// TODO: add file type validation!" >> /tmp/webapp-backup/upload.php && \
    echo "move_uploaded_file(\$_FILES['file']['tmp_name'], 'uploads/' . \$_FILES['file']['name']);" >> /tmp/webapp-backup/upload.php && \
    echo "?>" >> /tmp/webapp-backup/upload.php && \
    cd /tmp && \
    tar czf /srv/ftp/pub/webapp-backup.tar.gz webapp-backup/ && \
    rm -rf /tmp/webapp-backup

# Set permissions for FTP
RUN chmod -R 755 /srv/ftp && \
    chown -R ftp:ftp /srv/ftp

# Copy vsftpd config
COPY vsftpd.conf /etc/vsftpd/vsftpd.conf

# Initialize MariaDB (decoy - will be started but no useful data)
RUN mkdir -p /run/mysqld && \
    chown -R mysql:mysql /run/mysqld && \
    mkdir -p /run/openrc && \
    touch /run/openrc/softlevel

# Create entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 21 3306

ENTRYPOINT ["/entrypoint.sh"]
