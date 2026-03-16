FROM alpine:3.19

RUN apk add --no-cache \
    nmap-ncat \
    curl \
    iproute2 \
    net-tools \
    bash

EXPOSE 2

CMD ["ncat", "-l", "-k", "-p", "2", "-c", "echo FLAG{port2_not_in_top1000}"]
