FROM alpine:3.23.0

LABEL maintainer="d1ceward <github.com/d1ceward>"
LABEL org.opencontainers.image.source="https://github.com/d1ceward/unbound-for-pihole"
LABEL org.opencontainers.image.description="A lightweight Docker image for running Unbound as a recursive DNS resolver — the perfect upstream DNS server for Pi-hole."
LABEL org.opencontainers.image.licenses="MIT"

RUN apk --no-cache add unbound drill

# Get the root hints file
RUN mkdir -p /var/lib/unbound && \
    wget -S https://www.internic.net/domain/named.cache -O /var/lib/unbound/root.hints

# Copy the unbound configuration file
COPY unbound.conf /etc/unbound/unbound.conf

HEALTHCHECK --interval=30s --timeout=30s --start-period=10s --retries=3 CMD drill -p 5335 cloudflare.com @127.0.0.1 || exit 1

EXPOSE 5335/tcp
EXPOSE 5335/udp

CMD ["/usr/sbin/unbound", "-d", "-c", "/etc/unbound/unbound.conf"]
