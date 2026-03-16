FROM alpine:3.19

RUN apk add --no-cache openssh-server iptables && \
    ssh-keygen -A

RUN sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo "Banner /etc/ssh/banner" >> /etc/ssh/sshd_config

RUN echo "FLAG{ssh_version_detected}" > /etc/ssh/banner && \
    echo "" >> /etc/ssh/banner

RUN adduser -D -s /bin/ash labuser && \
    echo "labuser:$(head -c 32 /dev/urandom | base64)" | chpasswd

COPY start.sh /start.sh
RUN chmod +x /start.sh && sed -i 's/\r$//' /start.sh

EXPOSE 2222

CMD ["/start.sh"]
