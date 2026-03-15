FROM alpine:3.19

RUN apk update && apk add --no-cache \
    lighttpd \
    py3-flask \
    py3-gunicorn \
    bash \
    jq \
    sqlite \
    python3 \
    py3-pip

# Create necessary directories
RUN mkdir -p /var/lib/scoreboard \
    && mkdir -p /var/www/html

# Copy application files
COPY app.py /app/app.py
COPY www/index.html /var/www/html/index.html
COPY config/lighttpd.conf /etc/lighttpd/lighttpd.conf
COPY data/hashes.db /var/lib/scoreboard/hashes.db

# Initialize database directory
RUN touch /var/lib/scoreboard/state.db \
    && chmod 644 /var/lib/scoreboard/*.db

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080

WORKDIR /app

ENTRYPOINT ["/entrypoint.sh"]
