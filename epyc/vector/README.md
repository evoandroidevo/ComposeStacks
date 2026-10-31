# Vector

Ships this host's Docker container logs to VictoriaLogs on the Raspberry Pi through the logging stack's Caddy. It works like the [Raspberry Pi Vector stack](../../rpi/vector), which documents the log fields and behaviour, but it doesn't collect the host journal.

## Requirements

- A 1Password token file at `/etc/op/token`
- These fields in `DockerSecrets/logging-stack`:
  - `vector_user` and `vector_password`
  - `vector_endpoint`: the logging stack's base URL with no trailing slash, normally `http://<rpi-lan-ip>:8427`. `logs.*` is behind Authelia, so it won't work unless Authelia lets this host through
- A local log rotation policy in `/etc/docker/daemon.json` (`max-size` and `max-file`)
- The Loki logging driver removed from `/etc/docker/daemon.json`, see [migrating from the Loki driver](../../rpi/logging-stack/setup/docker/README.md)

The plain `http://` URL sends the credentials and logs unencrypted, so only use it on a trusted network.

## Start the stack

```bash
docker compose up -d
docker compose logs -f vector
```

## Verify

Run this on the Raspberry Pi. It should return recent lines:

```bash
curl -s http://localhost:8427/vl/select/logsql/query -d 'query=_time:5m host:="epyc" | limit 5'
```

## Log formatting

Lines in JSON, logfmt, or the VictoriaMetrics format are parsed by `shape_docker`. Other lines ship as they are. To handle an app's own format, add a route and a step for it, as in the [NUC config](../../nuc/vector/config/vector/vector.yaml).
