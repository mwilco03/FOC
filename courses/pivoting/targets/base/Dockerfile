FROM alpine:3.19

# Base setup for all challenge containers
RUN apk update && apk add --no-cache \
    bash \
    coreutils \
    openrc

# Basic system setup
RUN mkdir -p /run/openrc && \
    touch /run/openrc/softlevel

# Create standard directories
RUN mkdir -p /var/log /tmp

WORKDIR /root
