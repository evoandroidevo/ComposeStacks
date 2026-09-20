# Local stacks overview

This folder contains the local Docker-based stacks used for self-hosted services and supporting infrastructure.

<sub>Note: "local" refers to stacks intended to run on the same host as the main `dockhand` container (i.e., the services run on the same machine rather than remote hosts). Stacks that run on other machines that are managed by dockhand are located in the other folders in the repository root</sub>

## Stacks

- [dockhand](dockhand) — Docker management UI with a socket proxy and secret helper.
- [arr-stack](arr-stack) — a media-management helper stack centered around Seerr for requests and related media tooling.
- [authelia-lldap](authelia-lldap) — authentication and identity stack with Authelia, LLDAP, PostgreSQL, Redis, and secret injection.
- [logging-stack](logging-stack) — observability stack for logs and metrics with Grafana, VictoriaLogs, VictoriaMetrics, vmauth, vmalert, and Alertmanager.
- [proxy](proxy) — reverse proxy and ingress stack built around Caddy and Cloudflare Tunnel.

Work in progress:

- [irc-client](irc-client) — IRC web client stack using The Lounge.
- [cmms](cmms) — Atlas CMMS with PostgreSQL, MinIO, and Nginx.
- [forgejo](forgejo) — Forgejo stack configuration.
- [glances](glances) — Glance dashboard; the directory name is plural.
- [ups](ups) — PVE UPS stack.
- [wiki](wiki) — LeafWiki stack.

## Supporting folders

- [scripts](../common/scripts) — helper scripts used by the local stacks.

## Notes

- Many stacks rely on the external Docker network `proxy`. The proxy definition declares `logging-network`, but no active proxy service attaches to it; the logging stack uses its default network and `proxy`.
- Secret values are commonly injected at runtime from 1Password through the locket helper.
- Administrative web access should require Caddy/Authelia. Review [access-control concerns](../docs/codebase/CONCERNS.md#L1) before exposing services.
- Each stack is a separate Compose project. Check host prerequisites and [validation results](../docs/codebase/TESTING.md#L1) before starting one.
