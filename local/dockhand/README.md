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
