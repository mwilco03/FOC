FROM alpine:3.19

# Hop 6: DEPOT
# Services: tftp-hpa (69/UDP), net-snmp (161/UDP decoy)
# Landing user: (TFTP client - unauthenticated)
# Points: 500

RUN apk update && apk add --no-cache \
    bash \
    coreutils \
    openrc \
    openssh \
    tftp-hpa \
    net-snmp

# Create debug user for troubleshooting (non-challenge)
RUN adduser -D -s /bin/bash debug && \
    echo 'debug:Debug123!' | chpasswd

# Create TFTP root directory structure
RUN mkdir -p /var/tftpboot/firmware \
             /var/tftpboot/configs \
             /var/tftpboot/pxe

# Create TFTP content
RUN echo "TFTP Backup Server" > /var/tftpboot/README.txt && \
    echo "Firmware and configuration file repository" >> /var/tftpboot/README.txt

# Firmware directory (red herring)
RUN dd if=/dev/urandom of=/var/tftpboot/firmware/router-backup.bin bs=1024 count=100

# Configs directory (valuable loot)
RUN echo "# Switch Configuration Backup" > /var/tftpboot/configs/switch-config.txt && \
    echo "" >> /var/tftpboot/configs/switch-config.txt && \
    echo "hostname: core-switch-01" >> /var/tftpboot/configs/switch-config.txt && \
    echo "management_vlan: 100" >> /var/tftpboot/configs/switch-config.txt && \
    echo "dns_server: 172.20.7.xxx (RESOLVER)" >> /var/tftpboot/configs/switch-config.txt && \
    echo "dns_zone: lab.pivot.local" >> /var/tftpboot/configs/switch-config.txt && \
    echo "ntp_server: 172.20.1.1" >> /var/tftpboot/configs/switch-config.txt

RUN echo "# Firewall Rules Backup" > /var/tftpboot/configs/firewall-rules.bak && \
    echo "" >> /var/tftpboot/configs/firewall-rules.bak && \
    echo "# Allow Redis access (internal)" >> /var/tftpboot/configs/firewall-rules.bak && \
    echo "allow tcp from any to 172.20.8.0/24 port 6379" >> /var/tftpboot/configs/firewall-rules.bak && \
    echo "# Note: Redis has no auth configured (TODO: fix!)" >> /var/tftpboot/configs/firewall-rules.bak && \
    echo "" >> /var/tftpboot/configs/firewall-rules.bak && \
    echo "# PostgreSQL (internal only)" >> /var/tftpboot/configs/firewall-rules.bak && \
    echo "allow tcp from 172.20.0.0/16 to any port 5432" >> /var/tftpboot/configs/firewall-rules.bak

# PXE directory (red herring)
RUN echo "PXE Boot Documentation" > /var/tftpboot/pxe/README.txt && \
    echo "Network boot images would go here" >> /var/tftpboot/pxe/README.txt

# Set permissions
RUN chmod -R 755 /var/tftpboot

# Configure SNMP (decoy with junk OIDs)
RUN echo "rocommunity public" > /etc/snmp/snmpd.conf && \
    echo "syslocation Unknown" >> /etc/snmp/snmpd.conf && \
    echo "syscontact admin@pivot.local" >> /etc/snmp/snmpd.conf

# Configure OpenSSH (for troubleshooting)
RUN ssh-keygen -A

# Setup OpenRC
RUN mkdir -p /run/openrc && \
    touch /run/openrc/softlevel

# Create entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22 69/udp 161/udp

ENTRYPOINT ["/entrypoint.sh"]
