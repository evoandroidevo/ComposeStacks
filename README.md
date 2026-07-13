# ComposeStacks

This repository contains a set of Docker Compose stacks for local self-hosted services.

## Local stacks

- [local/authelia-lldap](local/authelia-lldap): Authelia with LLDAP, PostgreSQL, Redis, and secret injection
- [local/dockhand](local/dockhand): Dockhand UI with a Docker socket proxy and secret helpers
- [local/logging-stack](local/logging-stack): Grafana, VictoriaLogs, VictoriaMetrics, and alerting tools
- [local/proxy](local/proxy): Caddy reverse proxy with a Cloudflare Tunnel
- [local/arr-stack](local/arr-stack): media automation stack configuration
- [local/irc-client](local/irc-client): IRC client stack

## Getting started

Each stack lives in its own folder under [local](local) and includes its own README with service details, requirements, and startup steps.

From the repository root, you can browse the stack folders and run the relevant Compose commands from the directory you want to use.

## Notes

Many of the stacks rely on:

- Docker Compose
- an external Docker network named proxy
- secret values injected at runtime from 1Password or local secret templates
