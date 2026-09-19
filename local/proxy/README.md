# Proxy

This stack runs a reverse proxy with Caddy, a Cloudflare Tunnel entrypoint, and a secret injection helper for runtime configuration. It is designed to sit in front of other local services and expose them through a single ingress layer.

Status: current production, as confirmed on 2026-09-19. Administrative web access should require Caddy/Authelia; rendered route coverage has not been verified during this documentation refresh.

## What this stack provides

- Caddy as the main reverse proxy and TLS terminator
- Cloudflare Tunnel integration alongside directly published Caddy ports; actual internet exposure depends on host firewall and upstream routing
- Runtime secret injection through locket, using values from 1Password
- Custom Caddy modules for Cloudflare DNS, trapdoor, layer 4 handling, and other extensions

## Services

- locket: injects secrets from 1Password into the stack at runtime and materializes them into a temporary secret volume.
- cloudflare-tunnel: starts the Cloudflare Tunnel process using a token file mounted from the secret store.
- caddy: serves as the reverse proxy and exposes ports 80, 443, 443/udp, and 3890 (to restrict ldap layer4 routing to only the clients that need it).

## Requirements

- Docker and Docker Compose installed
- An 1Password token file available at /etc/op/token
- Secret templates present under ./config/caddy
- External Docker network `proxy`; `logging-network` is also declared but is not attached to any active service
- External Docker volume `parts-tracking_inventree_data`, with the `static` and `media` subpaths mounted by Caddy
- A valid Cloudflare Tunnel token available in 1Password under the configured secret reference

## Directory layout

- [compose.yaml](compose.yaml) — full service definition for locket, Cloudflare Tunnel, and Caddy
- [config/](config) — Caddy templates and other runtime configuration files
- [Dockerfile or inline build](compose.yaml) — custom Caddy image built with additional modules

## Start the stack

From this directory, run:

```bash
docker compose up -d
```

To follow logs:

```bash
docker compose logs -f
```

To inspect the status of a specific service:

```bash
docker compose ps
```

## Rebuild the custom Caddy image

If you change the Caddy build configuration or modules, rebuild the image with:

```bash
docker compose build caddy
```

Then restart the stack:

```bash
docker compose up -d --force-recreate caddy
```

## Secret handling

The locket service reads the 1Password token from /etc/op/token and injects runtime secrets into the shared tmpfs-backed secret volume. The Caddy container reads those generated files from /etc/caddy, and the Cloudflare Tunnel container reads the tunnel token from /run/secrets/tunnel_token.

## Notes

- The Caddy container is built from a custom image with additional modules for Cloudflare, trapdoor, and other integrations.
- The tunnel token is mounted from a tmpfs-backed secret store; the Compose file contains a 1Password reference, not the token value. Host swap/dump handling and other runtime persistence have not been audited.
- The proxy is intended to sit in front of other services and is connected to the external proxy network.
- No active service attaches to `logging-network`. The CrowdSec service block is commented out, even though CrowdSec modules are included in the Caddy build.
- The cloudflared healthcheck runs `cloudflared --version`; it does not verify a live tunnel connection.
