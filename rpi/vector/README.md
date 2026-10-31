# Vector

Ships this host's Docker container logs and systemd journal to VictoriaLogs through the logging stack's Caddy. The container logs come from the Docker API, so `daemon.json` and logging plugins are not involved.

Related setups:

- [NUC Vector stack](../../nuc/vector): Docker logs only
- [Proxmox host](../logging-stack/setup/proxmox): native package, journal only

## Services

- locket: writes the Vector login from 1Password to a tmpfs volume, where Vector reads them as `SECRET[...]` values
- socket-proxy: read-only access to the Docker API, not published outside the stack
- vector: collects, shapes, and sends the logs

## Requirements

- The [logging stack](../logging-stack) running on this host, publishing Caddy on port 8427
- A 1Password token file at `/etc/op/token`
- `vector_user` and `vector_password` fields in `DockerSecrets/logging-stack`
- A local log rotation policy in `/etc/docker/daemon.json` (`max-size` and `max-file`)
- The Loki logging driver removed from `/etc/docker/daemon.json`, see [migrating from the Loki driver](../logging-stack/setup/docker/README.md)

## Journal location

The Raspberry Pi's journal is not persistent, so the stack reads `/run/log/journal` by default. Logs still ship, but anything not yet sent is lost on reboot.

If you enable persistent storage, set `JOURNAL_DIR=/var/log/journal` in the stack's environment. To check where the journal is:

```bash
journalctl --header | grep -m1 'File path'
```

## Start the stack

```bash
docker compose up -d
docker compose logs -f vector
```

## Verify

Query VictoriaLogs from this host. Each query should return recent lines:

```bash
curl -s http://localhost:8427/vl/select/logsql/query -d 'query=_time:5m host:rpi source:docker | limit 5'
curl -s http://localhost:8427/vl/select/logsql/query -d 'query=_time:5m host:rpi source:journald | limit 5'
```

## Log fields

| Field | Docker | Journal |
| --- | --- | --- |
| `host` | `rpi` | `rpi` |
| `source` | `docker` | `journald` |
| `stack` | Compose project, or `standalone` | `host` |
| `service` | Compose service, or the container name | syslog identifier, or the unit if there is none |
| `container_name` | container name | not set |
| `stream` | `stdout` or `stderr` | not set |
| `level` | parsed from the line, if it has one | mapped from journal priority |
| `unit` | not set | systemd unit |

`host`, `stack`, and `service` are the VictoriaLogs stream fields. Don't add container IDs or image tags to them because their high cardinality slows VictoriaLogs down.

## Log parsing

Docker lines in JSON, logfmt, or the VictoriaMetrics format have their message and level extracted, and their other fields become log fields with nested keys flattened. Other lines are shipped as they are.

- Parsed fields can't overwrite the fields above or VictoriaLogs' reserved fields.
- Parsed fields whose names look like credentials, such as `authorization` or `token`, are dropped. This is only a name match: a line that isn't parsed, or a credential inside the message text, still ships unchanged.
- Lines with an empty message are dropped.

## Notes

- Logs written while Vector is stopped may not be shipped from Docker, so check for gaps after long outages. The journal source keeps a checkpoint in the `vector-data` volume and resumes where it stopped.
- While the endpoint is unreachable, Vector buffers up to 512 MiB on disk, then pauses reading. Containers keep running, but a long outage can still lose Docker lines once they rotate out of local logs.
- Run `docker compose up -d --force-recreate` after changing a secret in 1Password.
- If Vector logs a `403` from the Docker API, a proxy endpoint is disabled. Enable the matching variable on `socket-proxy`.
