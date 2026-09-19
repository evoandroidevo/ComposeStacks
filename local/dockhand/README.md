# Dockhand

This stack runs Dockhand along with a Docker socket proxy and a secret helper service for managing Docker-related credentials securely.

Status: work in progress, as confirmed on 2026-09-19. Administrative web access should require Caddy/Authelia.

## Services

- locket: provides secret injection using an 1Password token and stores temporary secret material in a tmpfs volume.
- socket-proxy: exposes the Docker socket to Dockhand with a restricted set of Docker API permissions.
- dockhand: exposes its web UI on container port 3000 without publishing a host port.

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

The Compose definition uses `expose: 3000`, not a host port mapping. Access requires a configured reverse-proxy route on the external `proxy` network. [TODO] Verify that route and its Caddy/Authelia access controls; `http://<your-host>:3000` is not established by this file.

## Notes

- The Dockhand container uses /opt/dockhand as its data directory.
- The encryption key is loaded from a tmpfs-backed secret file at startup. Host-level persistence and runtime disclosure were not audited.
- The socket-proxy service is isolated from the rest of the stack using an internal network.

## Expanded details

### Security and secrets

- `locket` materializes an `encryption_key` secret from 1Password into a tmpfs-backed `secrets-store-dockhand` volume. The `dockhand` container reads that key at startup via the custom entrypoint.
- The `socket-proxy` exposes a restricted set of Docker API endpoints only to the `dockhand` container. The proxy is configured as read-only for the Docker socket mount and uses environment flags to limit available endpoints.

### Socket proxy

- The `socket-proxy` service runs `tecnativa/docker-socket-proxy`. Its flags include POST, DELETE, EXEC, and container lifecycle operations as well as read endpoints. Treat Dockhand as privileged host administration; the socket's read-only bind mount does not make the API read-only.
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
