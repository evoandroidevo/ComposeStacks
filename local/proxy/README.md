# Proxy

This stack runs a reverse proxy with Caddy, a Cloudflare Tunnel, and a secret injection helper for runtime configuration.

## Services

- locket: injects secrets from 1Password into the stack at runtime.
- cloudflare-tunnel: connects the local services to Cloudflare Tunnel using a token file.
- caddy: serves as the reverse proxy and exposes ports 80, 443, and 3890.

## Requirements

- Docker and Docker Compose installed
- An 1Password token file available at /etc/op/token
- Secret templates present under ./config/caddy
- External Docker networks named proxy and logging-network

## Start the stack

From this directory, run:

```bash
docker compose up -d
```

To follow logs:

```bash
docker compose logs -f
```

## Notes

- The Caddy container is built from a custom image with additional modules for Cloudflare, trapdoor, and other integrations.
- The tunnel token is mounted from a temporary secret store at runtime.
- The proxy is intended to sit in front of other services and is connected to the external proxy network.
