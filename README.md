# ComposeStacks

This repository contains Docker Compose stacks for self-hosted services, grouped by deployment host: [local](local), [NAS](nas), and [Raspberry Pi](rpi).


## Local stacks

- [local/authelia-lldap](local/authelia-lldap): Authelia with LLDAP, PostgreSQL, Redis, and secret injection
- [local/dockhand](local/dockhand): Dockhand UI with a Docker socket proxy and secret helpers
- [local/logging-stack](local/logging-stack): Grafana, VictoriaLogs, VictoriaMetrics, and alerting tools
- [local/proxy](local/proxy): Caddy reverse proxy with a Cloudflare Tunnel
- [local/arr-stack](local/arr-stack): media automation stack configuration
- [local/irc-client](local/irc-client): IRC client stack
- [local/cmms](local/cmms): Atlas CMMS, PostgreSQL, MinIO, and Nginx
- [local/forgejo](local/forgejo): Forgejo stack configuration
- [local/glances](local/glances): Glance dashboard (the directory name is plural)
- [local/ups](local/ups): PVE UPS stack
- [local/wiki](local/wiki): LeafWiki stack

## Remote-host stacks

- [nas/agent](nas/agent): NAS agent stack
- [nas/kopia](nas/kopia): Kopia backup stack
- [rpi/agent](rpi/agent): Raspberry Pi agent stack
- [rpi/nut](rpi/nut): Network UPS Tools stack

## Getting started

Each stack has its own `compose.yaml` under its host directory. Some stacks also have a README with service details, requirements, and startup steps; otherwise, inspect the Compose definition and referenced configuration before deploying.

From the repository root, you can browse the stack folders and run the relevant Compose commands from the directory you want to use.

## Notes

Many of the stacks rely on:

- Docker Compose
- an external Docker network named proxy
- secret values injected at runtime from 1Password or local secret templates
