FROM alpine:3.19

RUN apk add --no-cache vsftpd

RUN mkdir -p /var/ftp/pub && \
    echo "FLAG{ftp_anonymous_access}" > /var/ftp/pub/flag.txt && \
    echo "Congratulations! You found the anonymous FTP share." > /var/ftp/pub/readme.txt

RUN echo "anonymous_enable=YES" > /etc/vsftpd/vsftpd.conf && \
    echo "local_enable=NO" >> /etc/vsftpd/vsftpd.conf && \
    echo "write_enable=NO" >> /etc/vsftpd/vsftpd.conf && \
    echo "anon_root=/var/ftp" >> /etc/vsftpd/vsftpd.conf && \
    echo "ftpd_banner=Welcome to Training Lab FTP - FLAG{ftp_anonymous_access}" >> /etc/vsftpd/vsftpd.conf && \
    echo "listen=YES" >> /etc/vsftpd/vsftpd.conf && \
    echo "listen_ipv6=NO" >> /etc/vsftpd/vsftpd.conf && \
    echo "seccomp_sandbox=NO" >> /etc/vsftpd/vsftpd.conf && \
    echo "pasv_enable=YES" >> /etc/vsftpd/vsftpd.conf && \
    echo "pasv_min_port=30000" >> /etc/vsftpd/vsftpd.conf && \
    echo "pasv_max_port=30009" >> /etc/vsftpd/vsftpd.conf

RUN mkdir -p /var/run/vsftpd/empty

EXPOSE 21 30000-30009

CMD ["vsftpd", "/etc/vsftpd/vsftpd.conf"]
