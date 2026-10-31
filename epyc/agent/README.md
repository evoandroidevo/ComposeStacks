# Agent

Runs the Hawser agent so [Dockhand](../../rpi/dockhand) on the Raspberry Pi can manage this host's Docker stacks.

## Requirements

- A 1Password token file at `/etc/op/token`
- An environment for this host in Dockhand, with its token saved to the `epyc-token` field in `DockerSecrets/dockhand`
- A `/opt/stacks` directory on this host
- Port 2376 reachable from the Raspberry Pi. Hawser has full access to the Docker socket, so don't expose this port more widely

## Start the stack

```bash
docker compose up -d
docker compose logs -f hawser
```

## Updates

The `dockhand.update=false` label stops Dockhand from updating the agent it depends on. To update it, run this on the host:

```bash
docker compose pull hawser
docker compose up -d hawser
```
