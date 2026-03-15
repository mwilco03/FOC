FROM alpine:3.19

# Add edge/testing repo for shellinabox (LAUNCHPAD only)
RUN echo 'https://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories \
    && apk update \
    && apk add --no-cache \
        shellinabox \
        bash \
        openssh-client \
        curl \
        openssl \
        nmap-ncat \
    && adduser -D -s /bin/bash player \
    && echo 'player:player' | chpasswd

# Create player home directory structure
RUN mkdir -p /home/player

# Download linpeas.sh for privilege escalation enumeration
# Note: For air-gapped builds, bundle linpeas.sh in the build context
RUN wget -O /home/player/linpeas.sh \
    https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh \
    && chmod +x /home/player/linpeas.sh \
    && chown player:player /home/player/linpeas.sh

# Copy briefing and reference materials
COPY briefing.txt /home/player/BRIEFING.txt
COPY lotl-reference.txt /home/player/LOTL-REFERENCE.txt

RUN chown -R player:player /home/player

EXPOSE 4200

# shellinabox configuration:
# -t: disable SSL (HTTP only per design decision)
# -b: background mode disabled (foreground for Docker)
# -p 4200: listen port
# --css: Black-on-White theme
# -s: session config (/:player:player:/home/player:/bin/bash)
CMD ["shellinaboxd", "-t", "-p", "4200", \
     "--css", "/etc/shellinabox/options-enabled/00+Black-on-White.css", \
     "-s", "/:player:player:/home/player:/bin/bash"]
