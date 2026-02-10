FROM alpine:3.19

# Hop 2: TUNNEL
# Services: OpenSSH (22/TCP), lighttpd (80/TCP decoy)
# Landing user: operator
# Points: 150

RUN apk update && apk add --no-cache \
    bash \
    coreutils \
    openrc \
    openssh \
    lighttpd

# Create operator user
RUN adduser -D -s /bin/bash operator && \
    echo 'operator:SecureOp2024!' | chpasswd

# Create user home structure
RUN mkdir -p /home/operator/.ssh && \
    chmod 700 /home/operator/.ssh

# Create network map breadcrumb
RUN echo "# Network Segment Map" > /home/operator/network-map.txt && \
    echo "" >> /home/operator/network-map.txt && \
    echo "Current segment: net-alpha (172.20.2.0/24)" >> /home/operator/network-map.txt && \
    echo "Next segment: net-bravo (172.20.3.0/24)" >> /home/operator/network-map.txt && \
    echo "FILESERV should be on net-bravo" >> /home/operator/network-map.txt && \
    echo "" >> /home/operator/network-map.txt && \
    echo "Services discovered:" >> /home/operator/network-map.txt && \
    echo "- FTP (port 21) - check for anonymous access" >> /home/operator/network-map.txt && \
    echo "- MySQL (port 3306) - may be locked down" >> /home/operator/network-map.txt

# Create bash history with breadcrumbs
RUN echo "ip addr" > /home/operator/.bash_history && \
    echo "ip route" >> /home/operator/.bash_history && \
    echo "cat /etc/hosts" >> /home/operator/.bash_history && \
    echo "# Discovered FILESERV at 172.20.3.xxx" >> /home/operator/.bash_history && \
    echo "# FTP service detected" >> /home/operator/.bash_history

RUN chown -R operator:operator /home/operator

# Configure OpenSSH
RUN ssh-keygen -A && \
    mkdir -p /run/openrc && \
    touch /run/openrc/softlevel

# Configure lighttpd decoy (404 page)
RUN mkdir -p /var/www/localhost/htdocs && \
    echo "<html><body><h1>404 - Service Decommissioned</h1><p>This web service has been retired.</p></body></html>" > /var/www/localhost/htdocs/index.html

# Create entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22 80

ENTRYPOINT ["/entrypoint.sh"]
