FROM alpine:3.19

# Hop 4: WEBSHELL
# Services: lighttpd + PHP (80/TCP), dnsmasq (53/UDP decoy)
# Landing user: www-data -> root (via SUID find)
# Points: 300
# PRIVILEGE ESCALATION HERE

RUN apk update && apk add --no-cache \
    bash \
    coreutils \
    openrc \
    lighttpd \
    php83 \
    php83-cgi \
    dnsmasq \
    findutils

# Configure lighttpd with PHP
RUN mkdir -p /var/www/localhost/htdocs/uploads && \
    chmod 777 /var/www/localhost/htdocs/uploads

# Create vulnerable upload form
RUN echo '<!DOCTYPE html>' > /var/www/localhost/htdocs/index.html && \
    echo '<html><head><title>File Upload Service</title></head><body>' >> /var/www/localhost/htdocs/index.html && \
    echo '<h1>Internal File Upload Service</h1>' >> /var/www/localhost/htdocs/index.html && \
    echo '<form action="upload.php" method="post" enctype="multipart/form-data">' >> /var/www/localhost/htdocs/index.html && \
    echo '  Select file to upload:' >> /var/www/localhost/htdocs/index.html && \
    echo '  <input type="file" name="fileToUpload" id="fileToUpload">' >> /var/www/localhost/htdocs/index.html && \
    echo '  <input type="submit" value="Upload" name="submit">' >> /var/www/localhost/htdocs/index.html && \
    echo '</form>' >> /var/www/localhost/htdocs/index.html && \
    echo '<!-- TODO: add file type validation -->' >> /var/www/localhost/htdocs/index.html && \
    echo '</body></html>' >> /var/www/localhost/htdocs/index.html

# Create vulnerable upload.php
RUN echo '<?php' > /var/www/localhost/htdocs/upload.php && \
    echo '$target_dir = "uploads/";' >> /var/www/localhost/htdocs/upload.php && \
    echo '$target_file = $target_dir . basename($_FILES["fileToUpload"]["name"]);' >> /var/www/localhost/htdocs/upload.php && \
    echo 'if (move_uploaded_file($_FILES["fileToUpload"]["tmp_name"], $target_file)) {' >> /var/www/localhost/htdocs/upload.php && \
    echo '    echo "File uploaded: " . htmlspecialchars(basename($_FILES["fileToUpload"]["name"]));' >> /var/www/localhost/htdocs/upload.php && \
    echo '} else {' >> /var/www/localhost/htdocs/upload.php && \
    echo '    echo "Upload failed.";' >> /var/www/localhost/htdocs/upload.php && \
    echo '}' >> /var/www/localhost/htdocs/upload.php && \
    echo '?>' >> /var/www/localhost/htdocs/upload.php

# Set SUID bit on find (PRIVILEGE ESCALATION VECTOR)
RUN chmod u+s /usr/bin/find

# Create root credentials for next hop
RUN mkdir -p /root/.deployment && \
    echo "# DROPZONE SSH Credentials" > /root/.deployment/dropzone-creds.txt && \
    echo "User: deployer" >> /root/.deployment/dropzone-creds.txt && \
    echo "Password: D3pl0y2024Secure" >> /root/.deployment/dropzone-creds.txt && \
    echo "Note: deployer has sudo access for rc-service and apk" >> /root/.deployment/dropzone-creds.txt

# Copy lighttpd config
COPY lighttpd.conf /etc/lighttpd/lighttpd.conf

# Configure dnsmasq (decoy)
RUN mkdir -p /etc/dnsmasq.d && \
    echo "port=53" > /etc/dnsmasq.d/basic.conf && \
    echo "listen-address=127.0.0.1" >> /etc/dnsmasq.d/basic.conf

# Setup OpenRC
RUN mkdir -p /run/openrc && \
    touch /run/openrc/softlevel

# Create entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80 53/udp

ENTRYPOINT ["/entrypoint.sh"]
