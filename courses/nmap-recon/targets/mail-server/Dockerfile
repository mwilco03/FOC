FROM alpine:3.19

RUN apk add --no-cache postfix dovecot bash

RUN postconf -e "smtpd_banner=mail.training.lab ESMTP FLAG{smtp_banner_captured}" && \
    postconf -e "myhostname=mail.training.lab" && \
    postconf -e "mydomain=training.lab" && \
    postconf -e "inet_interfaces=all" && \
    postconf -e "inet_protocols=ipv4"

RUN echo "protocols = imap" > /etc/dovecot/local.conf && \
    echo "listen = *" >> /etc/dovecot/local.conf && \
    echo "ssl = no" >> /etc/dovecot/local.conf && \
    echo "disable_plaintext_auth = no" >> /etc/dovecot/local.conf && \
    echo "mail_location = mbox:~/mail:INBOX=/var/mail/%u" >> /etc/dovecot/local.conf

COPY start.sh /start.sh
RUN chmod +x /start.sh && sed -i 's/\r$//' /start.sh

EXPOSE 25 143

CMD ["/start.sh"]
