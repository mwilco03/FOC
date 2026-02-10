FROM alpine:3.19

# Hop 7: RESOLVER
# Services: BIND (53/TCP+UDP), lighttpd (80/TCP honeypot)
# Landing user: (DNS queries)
# Points: 600

RUN apk update && apk add --no-cache \
    bash \
    coreutils \
    openrc \
    bind \
    lighttpd

# Create BIND configuration directory
RUN mkdir -p /etc/bind /var/bind /var/run/named && \
    chown -R named:named /var/bind /var/run/named

# Copy BIND configuration files
COPY named.conf /etc/bind/named.conf
COPY db.lab.pivot.local /var/bind/db.lab.pivot.local

RUN chown named:named /etc/bind/named.conf /var/bind/db.lab.pivot.local

# Configure lighttpd honeypot (fake router admin page)
RUN mkdir -p /var/www/localhost/htdocs && \
    echo '<html><head><title>Router Admin</title></head><body>' > /var/www/localhost/htdocs/index.html && \
    echo '<h1>Router Administration Panel</h1>' >> /var/www/localhost/htdocs/index.html && \
    echo '<form action="login.php" method="post">' >> /var/www/localhost/htdocs/index.html && \
    echo '  Username: <input type="text" name="user"><br>' >> /var/www/localhost/htdocs/index.html && \
    echo '  Password: <input type="password" name="pass"><br>' >> /var/www/localhost/htdocs/index.html && \
    echo '  <input type="submit" value="Login">' >> /var/www/localhost/htdocs/index.html && \
    echo '</form></body></html>' >> /var/www/localhost/htdocs/index.html

# Setup OpenRC
RUN mkdir -p /run/openrc && \
    touch /run/openrc/softlevel

# Create entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 53/tcp 53/udp 80

ENTRYPOINT ["/entrypoint.sh"]
