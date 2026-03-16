FROM python:3.11-alpine

RUN apk add --no-cache nmap-ncat iptables openssh-server bash && \
    ssh-keygen -A

# SSH on non-standard port buried high
RUN sed -i 's/#Port 22/Port 22222/' /etc/ssh/sshd_config && \
    adduser -D -s /bin/ash ghost && \
    echo "ghost:$(head -c 32 /dev/urandom | base64)" | chpasswd

COPY services.py /app/services.py
COPY start.sh /start.sh
RUN sed -i 's/\r$//' /start.sh /app/services.py
RUN chmod +x /start.sh

EXPOSE 2 1337 7000 8000 9000 22222 31337 65000

CMD ["/start.sh"]
