# NUC stacks overview

This folder contains the Docker Compose stacks for services and supporting infrastructure deployed on the NUC. See the [repository overview](../README.md) for stacks deployed on other hosts.

## Stacks

- [agent](agent): NUC agent stack.
- [authelia-lldap](authelia-lldap): authentication and identity stack with Authelia, LLDAP, PostgreSQL, Redis, and secret injection.
- [cmms](cmms): Atlas CMMS with PostgreSQL, MinIO, and Nginx.
- [forgejo](forgejo): Forgejo stack configuration.
- [glances](glances): Glance dashboard
- [proxy](proxy): reverse proxy and ingress stack built around Caddy and Cloudflare Tunnel.
- [wiki](wiki): LeafWiki stack.

## Supporting folders

- [Shared scripts](../common/scripts): reusable container initialization helpers. Preserve the repository layout when a stack references these scripts.

## Notes

- Check each stack's external network requirements, including `proxy`, before deployment.
- Secret values are commonly injected at runtime from 1Password through the locket helper.
- Administrative web access should require Caddy/Authelia. Review authentication and routing before exposing services.
- Each stack is a separate Compose project. Review its `compose.yaml`, environment variables, secrets, and bind-mount paths, then run Compose commands from that stack's directory.
- Read the stack-specific READMEs where available, particularly for [authentication](authelia-lldap/README.md) and [proxy](proxy/README.md).
