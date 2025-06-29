FROM alpine:3.22

LABEL maintainer="d1ceward <github.com/d1ceward>"
LABEL org.opencontainers.image.source="https://github.com/d1ceward/unbound-for-pihole"
LABEL org.opencontainers.image.description="Lightweight Unbound DNS resolver for Pi-hole with DNSSEC and root hints."
LABEL org.opencontainers.image.licenses="MIT"

RUN apk --no-cache add unbound drill \
    && adduser -D -H -u 1000 unbounduser \
    && mkdir -p /etc/unbound \
    && chown -R unbounduser:unbounduser /etc/unbound

# Get the root hints file
RUN wget -S https://www.internic.net/domain/named.cache -O /etc/unbound/root.hints \
    && chown unbounduser:unbounduser /etc/unbound/root.hints

# Copy the unbound configuration file
COPY unbound.conf /etc/unbound/unbound.conf
RUN chown unbounduser:unbounduser /etc/unbound/unbound.conf

HEALTHCHECK --interval=30s --timeout=30s --start-period=10s --retries=3 CMD drill -p 5335 cloudflare.com @127.0.0.1 || exit 1

EXPOSE 5335/tcp
EXPOSE 5335/udp

USER unbounduser

CMD ["/usr/sbin/unbound", "-d", "-c", "/etc/unbound/unbound.conf"]
