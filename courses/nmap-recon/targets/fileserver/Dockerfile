FROM python:3.11-alpine

RUN apk add --no-cache \
    vsftpd openssh samba bash net-tools

# SSH on 22
RUN ssh-keygen -A && \
    adduser -D fileadmin && echo "fileadmin:F1l3S3rv3r!" | chpasswd

# FTP on 21
RUN mkdir -p /var/ftp/pub /var/ftp/confidential /var/run/vsftpd/empty && \
    echo "FLAG{ftp_anonymous_access}" > /var/ftp/pub/flag.txt && \
    echo "CONFIDENTIAL: FLAG{sensitive_data_exposed}" > /var/ftp/confidential/passwords.txt

COPY ftp_server.py /app/ftp_server.py

# Samba on 139/445
RUN mkdir -p /srv/share && \
    echo "FLAG{smb_guest_share_open}" > /srv/share/flag.txt
COPY smb.conf /etc/samba/smb.conf

COPY start.sh /start.sh
RUN sed -i 's/\r$//' /start.sh
RUN chmod +x /start.sh

EXPOSE 21 22 139 445
CMD ["/start.sh"]
