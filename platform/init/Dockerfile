FROM alpine:3.19

RUN apk update && apk add --no-cache bash openssl

COPY generate.sh /generate.sh
RUN chmod +x /generate.sh

CMD ["/generate.sh"]
