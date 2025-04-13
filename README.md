# unbound-for-pihole 🛡️🚀

A lightweight Docker image for running [Unbound](https://nlnetlabs.nl/projects/unbound/about/) as a recursive DNS resolver — the perfect upstream DNS server for [Pi-hole](https://pi-hole.net/).

## Usage

### 1. Run Unbound container

```bash
docker run -d \
  --name=unbound \
  --restart=unless-stopped \
  -p 5335:5335/tcp \
  -p 5335:5335/udp \
  ghcr.io/d1ceward/unbound-for-pihole
```

> Ports 5335 are used here to avoid conflict with Pi-hole. Pi-hole will be configured to forward to 127.0.0.1#5335.

### 2. Configure Pi-hole

In your Pi-hole web interface:
- Go to Settings > DNS
- Under Upstream DNS Servers, check Custom 1 (IPv4) and enter:

```
127.0.0.1#5335
```

Save and flush the DNS cache via Pi-hole's Tools > Flush Network Table if needed.

## Configuration

A unbound.conf is included with:

- Root hints loading
- DNSSEC validation
- Prefetching and caching
- Safe settings to avoid DNS leaks

You can mount a custom config if desired:

```bash
-v custom-config/unbound.conf:/etc/unbound/unbound.conf:ro
```

## Build it yourself

```bash
git clone https://github.com/d1ceward/unbound-for-pihole.git
cd unbound-for-pihole
docker build -t unbound-for-pihole .
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/d1ceward/unbound-for-pihole. By contributing you agree to abide by the Code of Merit.

1. Fork it (<https://github.com/d1ceward/unbound-for-pihole/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [d1ceward](https://github.com/d1ceward) - creator and maintainer
