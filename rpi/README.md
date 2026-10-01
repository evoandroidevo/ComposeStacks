# Raspberry Pi stacks overview

This folder contains the Docker Compose stacks for management, observability, and UPS services deployed on the Raspberry Pi. See the [repository overview](../README.md) for stacks deployed on other hosts.

## Stacks

- [dockhand](dockhand): Docker management UI with a socket proxy and secret helper.
- [logging-stack](logging-stack): observability stack for logs and metrics with Grafana, VictoriaLogs, VictoriaMetrics, vmauth, vmalert, and Alertmanager.
- [nut](nut): Network UPS Tools stack.
- [ups](ups): PVE UPS stack.

## Supporting folders

- [Shared scripts](../common/scripts): reusable container initialization helpers. Preserve the repository layout when a stack references these scripts.

## Notes

- Check each stack's external network requirements, including `proxy`, before deployment.
- Secret values are commonly injected at runtime from 1Password through the locket helper.
- Administrative web access should require Caddy/Authelia. Review authentication and routing before exposing services.
- Each stack is a separate Compose project. Review its `compose.yaml`, environment variables, secrets, and bind-mount paths, then run Compose commands from that stack's directory.
- Verify container image support for the Raspberry Pi's CPU architecture and any required UPS device access before deployment.
- Read the stack-specific READMEs where available, particularly for [Dockhand](dockhand/README.md) and [logging](logging-stack/README.md).
