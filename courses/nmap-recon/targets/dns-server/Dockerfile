FROM python:3.11-alpine

RUN apk add --no-cache dnsmasq

COPY dnsmasq.conf /etc/dnsmasq.conf
COPY server.py /app/server.py

EXPOSE 53/tcp 53/udp 5353/tcp

# Run dnsmasq in background and a TCP banner server on 5353
CMD ["sh", "-c", "dnsmasq && python3 /app/server.py"]
