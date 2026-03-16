FROM zeek/zeek:latest

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl jq && rm -rf /var/lib/apt/lists/*

COPY process-pcap.sh /process-pcap.sh
RUN sed -i 's/\r$//' /process-pcap.sh
RUN chmod +x /process-pcap.sh

ENTRYPOINT ["/process-pcap.sh"]
