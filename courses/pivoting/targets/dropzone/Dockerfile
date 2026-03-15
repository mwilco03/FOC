FROM alpine:3.19

# Hop 5: DROPZONE
# Services: OpenSSH (22/TCP), vsftpd (21/TCP locked down)
# Installed but STOPPED: lighttpd + mod_webdav + PHP
# Landing user: deployer (sudo for rc-service, apk)
# Points: 400

RUN apk update && apk add --no-cache \
    bash \
    coreutils \
    openrc \
    openssh \
    lighttpd \
    lighttpd-mod_webdav \
    php83 \
    php83-cgi \
    vsftpd \
    sudo

# Create deployer user
RUN adduser -D -s /bin/bash deployer && \
    echo 'deployer:D3pl0y2024Secure' | chpasswd

# Create user home structure
RUN mkdir -p /home/deployer/.ssh && \
    chmod 700 /home/deployer/.ssh

# Configure sudo for deployer (scoped sudo)
RUN echo "deployer ALL=(root) NOPASSWD: /sbin/rc-service *, /sbin/apk *" > /etc/sudoers.d/deployer && \
    chmod 440 /etc/sudoers.d/deployer

# Configure lighttpd with WebDAV (installed but NOT started)
RUN mkdir -p /var/www/localhost/webdav && \
    chmod 755 /var/www/localhost/webdav

COPY lighttpd.conf /etc/lighttpd/lighttpd.conf

# Configure vsftpd (locked down - no anonymous, strong auth required)
RUN mkdir -p /var/run/vsftpd/empty
COPY vsftpd.conf /etc/vsftpd/vsftpd.conf

# Configure OpenSSH
RUN ssh-keygen -A && \
    mkdir -p /run/openrc && \
    touch /run/openrc/softlevel

# Create entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN chown -R deployer:deployer /home/deployer

EXPOSE 21 22 80

ENTRYPOINT ["/entrypoint.sh"]
