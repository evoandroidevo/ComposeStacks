# Epyc stacks overview

This folder contains Docker Compose stacks for media automation and IRC. See the [repository overview](../README.md) for stacks deployed on the NAS, NUC, and Raspberry Pi.

## Stacks

- [arr-stack](arr-stack): media automation, requests, and related media tooling.

Work in progress:

- [irc-client](irc-client): IRC web client stack using The Lounge.

## Supporting folders

- [Shared scripts](../common/scripts): reusable container initialization helpers. Preserve the repository layout when a stack references these scripts.

## Notes

- Check each stack's external network requirements, including `proxy`, before deployment.
- Secret values are commonly injected at runtime from 1Password through the locket helper.
- Administrative web access should require Caddy/Authelia. Review authentication and routing before exposing services.
- Each stack is a separate Compose project. Review its `compose.yaml`, environment variables, secrets, and bind-mount paths, then run Compose commands from that stack's directory.
