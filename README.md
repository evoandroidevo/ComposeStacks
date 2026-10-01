# ComposeStacks

This repository contains Docker Compose stacks for self-hosted services, grouped by deployment host: [local](local), [NAS](nas), [NUC](nuc), and [Raspberry Pi](rpi).

## Local stacks

- [epyc/arr-stack](epyc/arr-stack): media automation stack configuration
- [epyc/irc-client](epyc/irc-client): IRC client stack

## NAS stacks

- [nas/agent](nas/agent): NAS agent stack
- [nas/kopia](nas/kopia): Kopia backup stack

## NUC stacks

- [nuc/agent](nuc/agent): NUC agent stack
- [nuc/authelia-lldap](nuc/authelia-lldap): Authelia with LLDAP, PostgreSQL, Redis, and secret injection
- [nuc/cmms](nuc/cmms): Atlas CMMS, PostgreSQL, MinIO, and Nginx
- [nuc/forgejo](nuc/forgejo): Forgejo stack configuration
- [nuc/glances](nuc/glances): Glance dashboard (the directory name is plural)
- [nuc/proxy](nuc/proxy): Caddy reverse proxy with a Cloudflare Tunnel
- [nuc/wiki](nuc/wiki): LeafWiki stack

## Raspberry Pi stacks

- [rpi/dockhand](rpi/dockhand): Dockhand UI with a Docker socket proxy and secret helpers
- [rpi/logging-stack](rpi/logging-stack): Grafana, VictoriaLogs, VictoriaMetrics, and alerting tools
- [rpi/nut](rpi/nut): Network UPS Tools stack
- [rpi/ups](rpi/ups): PVE UPS stack

## Shared scripts

[common/scripts](common/scripts) contains reusable container initialization helpers for loading environment variables from files, copying files, creating symlinks, and setting volume ownership.

## Getting started

Each stack has its own `compose.yaml` under its host directory. Some stacks also have a README with service details, requirements, and startup steps; otherwise, inspect the Compose definition and referenced configuration before deploying.

Choose the stack for the target host, configure its required environment variables and secrets, and check bind-mount paths and external networks before starting it. Run the relevant Compose commands from that stack's directory. Preserve the repository layout when a stack references shared files under `common/`.

## Notes

Many of the stacks rely on:

- Docker Compose
- an external Docker network named `proxy`
- secret values injected at runtime from 1Password or local secret templates
