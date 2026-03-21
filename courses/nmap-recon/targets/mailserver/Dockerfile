FROM python:3.11-alpine

RUN apk add --no-cache \
    postfix dovecot dovecot-pop3d openssh nginx bash net-tools

# SSH on 22
RUN ssh-keygen -A && \
    adduser -D mailadmin && echo "mailadmin:M4ilS3rv3r!" | chpasswd

# Postfix SMTP on 25
RUN postconf -e "smtpd_banner=mail.corp.local ESMTP FLAG{smtp_banner_captured}" && \
    postconf -e "myhostname=mail.corp.local" && \
    postconf -e "mydomain=corp.local" && \
    postconf -e "inet_interfaces=all" && \
    postconf -e "inet_protocols=ipv4"

# Dovecot IMAP on 143, POP3 on 110
RUN printf 'dovecot_config_version = 2.4.0\ndovecot_storage_version = 2.4.0\nprotocols = imap pop3\nlisten = *\nssl = no\nauth_mechanisms = plain login\n' \
    > /etc/dovecot/dovecot.conf

# Webmail on 443 (HTTPS with self-signed cert)
RUN apk add --no-cache openssl && \
    mkdir -p /var/www/html /run/nginx /etc/nginx/ssl && \
    openssl req -x509 -newkey rsa:2048 -nodes \
        -keyout /etc/nginx/ssl/webmail.key \
        -out /etc/nginx/ssl/webmail.crt \
        -days 3650 -subj "/CN=mail.corp.local/O=Corp/C=US"
COPY webmail.html /var/www/html/index.html
RUN printf 'server {\n\
    listen 443 ssl;\n\
    ssl_certificate /etc/nginx/ssl/webmail.crt;\n\
    ssl_certificate_key /etc/nginx/ssl/webmail.key;\n\
    root /var/www/html;\n\
    index index.html;\n\
}\n' > /etc/nginx/http.d/default.conf

# SMTP challenge on 2525
COPY smtp_challenge.py /app/smtp_challenge.py

COPY start.sh /start.sh
RUN sed -i 's/\r$//' /start.sh /app/smtp_challenge.py
RUN chmod +x /start.sh

EXPOSE 22 25 110 143 443 2525
CMD ["/start.sh"]
