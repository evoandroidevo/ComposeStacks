# Dockhand

This stack runs Dockhand along with a Docker socket proxy and a secret helper service for managing Docker-related credentials securely.

## Services

- locket: provides secret injection using an 1Password token and stores temporary secret material in a tmpfs volume.
- socket-proxy: exposes the Docker socket to Dockhand with a restricted set of Docker API permissions.
- dockhand: serves the Dockhand web UI on port 3000.

## Requirements

- Docker and Docker Compose installed
- An 1Password token file available at /etc/op/token
- An external Docker network named proxy
- A writable data directory at /opt/dockhand

## Start the stack

From this directory, run:

```bash
docker compose up -d
```

To view logs:

```bash
docker compose logs -f
```

## Access

Open the web interface at:

```text
http://<your-host>:3000
```

## Notes

- The Dockhand container uses /opt/dockhand as its data directory.
- The encryption key is loaded from the secret file at runtime rather than written to disk.
- The socket-proxy service is isolated from the rest of the stack using an internal network.

## Expanded details

### Security and secrets

- `locket` materializes an `encryption_key` secret from 1Password into a tmpfs-backed `secrets-store-dockhand` volume. The `dockhand` container reads that key at runtime via the custom entrypoint — the key is never written into the repository or persisted to disk.
- The `socket-proxy` exposes a restricted set of Docker API endpoints only to the `dockhand` container. The proxy is configured as read-only for the Docker socket mount and uses environment flags to limit available endpoints.

### Socket proxy

- The `socket-proxy` service runs `tecnativa/docker-socket-proxy` and limits access to only the APIs Dockhand requires (containers, images, networks, volumes, events, and a small set of POST/DELETE actions). This reduces risk from exposing the full Docker socket.
- The proxy is attached to an internal `socket-proxy` network; only containers on that network (and explicitly connected networks) can access it.

### Data directory

- Dockhand persists application data under `/opt/dockhand` on the host. Ensure this directory is writable by the container user and has appropriate backup/restore processes in place.

### Health and maintenance

- To rotate the encryption key or other secrets, update the 1Password template referenced by `locket`, then restart `locket` and `dockhand` so the new secret is materialized and picked up by the entrypoint.

### Troubleshooting

- Dockhand fails to start: check `docker compose logs dockhand` for entrypoint errors; ensure `secrets-store-dockhand` contains `encryption_key` produced by `locket`.
- Socket issues: if Dockhand cannot access container information, verify `socket-proxy` is running and `CONTAINERS`/`INFO` flags are enabled in the proxy environment.
- Permissions: if Dockhand cannot write to `/opt/dockhand`, ensure host permissions allow the container user (`PUID=1000`) to write.

## See also

- `compose.yaml` in this directory for service configuration and network topology.
