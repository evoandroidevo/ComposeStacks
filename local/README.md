# Local stacks overview

This folder contains the local Docker-based stacks used for self-hosted services and supporting infrastructure.

<sub>Note: "local" refers to stacks intended to run on the same host as the main `dockhand` container (i.e., the services run on the same machine rather than remote hosts). Stacks that run on other machines that are managed by dockhand are located in the other folders in the repository root</sub>

## Stacks

- [arr-stack](arr-stack) — a media-management helper stack centered around Seerr for requests and related media tooling.
- [authelia-lldap](authelia-lldap) — authentication and identity stack with Authelia, LLDAP, PostgreSQL, Redis, and secret injection.
- [dockhand](dockhand) — Docker management UI with a socket proxy and secret helper for safer container administration.
- [irc-client](irc-client) — a lightweight IRC web client stack using The Lounge.
- [logging-stack](logging-stack) — observability stack for logs and metrics with Grafana, VictoriaLogs, VictoriaMetrics, vmauth, vmalert, and Alertmanager.
- [proxy](proxy) — reverse proxy and ingress stack built around Caddy and Cloudflare Tunnel.

## Supporting folders

- [scripts](../common/scripts) — helper scripts used by the local stacks.

## Notes

- Many of these stacks rely on shared Docker networks such as proxy and logging-network.
- Secret values are commonly injected at runtime from 1Password through the locket helper.
- Start each stack from its own directory with Docker Compose when you want to bring it up independently.
