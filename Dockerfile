FROM alpine:3.22

RUN apk --no-cache add unbound drill

# Get the root hints file
RUN wget -S https://www.internic.net/domain/named.cache -O /etc/unbound/root.hints

# Copy the unbound configuration file
COPY unbound.conf /etc/unbound/unbound.conf

HEALTHCHECK --interval=30s --timeout=30s --start-period=10s --retries=3 CMD drill -p 5335 cloudflare.com @127.0.0.1 || exit 1

EXPOSE 5335/tcp
EXPOSE 5335/udp

CMD ["/usr/sbin/unbound", "-d", "-c", "/etc/unbound/unbound.conf"]
