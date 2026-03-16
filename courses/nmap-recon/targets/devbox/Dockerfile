FROM python:3.11-alpine

RUN apk add --no-cache openssh bash net-tools

# SSH on 2222
RUN ssh-keygen -A && \
    sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config && \
    echo "Banner /etc/ssh/banner" >> /etc/ssh/sshd_config && \
    adduser -D developer && echo "developer:devpass123" | chpasswd
RUN echo "FLAG{ssh_version_detected}" > /etc/ssh/banner

# DNS on 5353
COPY dns_server.py /app/dns_server.py

# Custom apps on 4444, 5555, 6666, 9999
COPY services.py /app/services.py

COPY start.sh /start.sh
RUN sed -i 's/\r$//' /start.sh /app/services.py /app/dns_server.py
RUN chmod +x /start.sh

EXPOSE 2222 4444 5353 5555 6666 9999
CMD ["/start.sh"]
