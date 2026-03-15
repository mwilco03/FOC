FROM alpine:3.19

# Hop 8: CACHE
# Services: Redis (6379/TCP, no auth), OpenSSH (22/TCP), PostgreSQL (5432/TCP decoy)
# Landing user: redis
# Points: 800

RUN apk update && apk add --no-cache \
    bash \
    coreutils \
    openrc \
    redis \
    openssh \
    postgresql16 \
    postgresql16-client

# Create redis user with shell access
RUN adduser -D -s /bin/bash redis && \
    echo 'redis:redis' | chpasswd

# Create user home structure
RUN mkdir -p /home/redis/.ssh && \
    chmod 700 /home/redis/.ssh && \
    chown -R redis:redis /home/redis

# Configure Redis (NO PASSWORD - vulnerable)
RUN mkdir -p /etc/redis && \
    echo "bind 0.0.0.0" > /etc/redis/redis.conf && \
    echo "port 6379" >> /etc/redis/redis.conf && \
    echo "protected-mode no" >> /etc/redis/redis.conf && \
    echo "dir /var/lib/redis" >> /etc/redis/redis.conf && \
    echo "dbfilename dump.rdb" >> /etc/redis/redis.conf && \
    echo "# NO PASSWORD SET - VULNERABLE!" >> /etc/redis/redis.conf

RUN mkdir -p /var/lib/redis && \
    chown redis:redis /var/lib/redis

# Configure OpenSSH
RUN ssh-keygen -A

# Configure PostgreSQL (decoy)
RUN mkdir -p /run/postgresql && \
    chown postgres:postgres /run/postgresql

# Setup OpenRC
RUN mkdir -p /run/openrc && \
    touch /run/openrc/softlevel

# Create entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 6379 22 5432

ENTRYPOINT ["/entrypoint.sh"]
