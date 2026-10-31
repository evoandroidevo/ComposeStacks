# Logging Stack

This stack provides a lightweight observability environment for logs and metrics using Grafana, VictoriaLogs, VictoriaMetrics, Caddy, vmalert, and Alertmanager. It is intended to collect, store, and visualize operational data for the local services in this repository.

Status: current production, as confirmed on 2026-09-19. Administrative web access should require Caddy/Authelia. The configuration grants anonymous Grafana users the Admin role, so access-control enforcement must be verified at the proxy and network boundary.

## What this stack provides

- Grafana for dashboards and log/metric exploration
- VictoriaLogs for storing and querying logs
- VictoriaMetrics for storing and querying metrics
- Caddy as the entry point to the stack, controlling access and routing requests to the Victoria products and Grafana
- vmalert and Alertmanager for alert evaluation and routing; notification delivery is not configured
- locket for injecting runtime secrets from 1Password

## Services

- grafana: web UI for dashboards and log/metric exploration
- victorialogs: stores and serves logs internally on port 9428
- victoriametrics: stores and serves metrics internally on port 8428
- caddy: published on port 8427, enforces access and routes requests to the appropriate backend based on the request path
- vmalert: evaluates alerting and recording rules
- alertmanager: handles alert notifications
- locket: injects secrets from 1Password into the stack at runtime

## Requirements

- Docker and Docker Compose installed
- An 1Password token file available at /etc/op/token
- Configuration files present under ./config/
- An external Docker network named `proxy`; internal services use the project's default network
- Valid secret values for Grafana domain settings in your 1Password store
- These fields in `DockerSecrets/logging-stack`: `docker_user`, `docker_password_hash`, `vector_user`, `vector_password_hash`, and `grafana_proxy_secret`. Locket fails if any are missing, see [generating password hashes](#generating-password-hashes)

## Directory layout

- [compose.yaml](compose.yaml) — main stack definition and service wiring
- [config/](config) — Grafana provisioning, datasource config, alert rules, and the Caddyfile
- [setup/docker](setup/docker) — Loki logging driver setup, and how to migrate a host from it to Vector
- [setup/jellyfin](setup/jellyfin) — Vector-based Jellyfin log forwarding and setup notes
- [setup/proxmox](setup/proxmox) — Vector-based Proxmox host journal forwarding

Container and host logs from the Raspberry Pi and NUC are shipped by the [rpi/vector](../vector) and [nuc/vector](../../nuc/vector) stacks.

## Start the stack

From this directory, run:

```bash
docker compose up -d
```

To view logs for all services:

```bash
docker compose logs -f
```

To view the current container status:

```bash
docker compose ps
```

## Access the UI

Once the stack is running, Grafana is available through the reverse proxy network as configured by the stack's environment and secret files. If your setup exposes it directly, it is typically served on the host's configured reverse proxy route rather than a standalone host port.

Only Caddy publishes a host port, 8427. The other services are reachable only from inside the stack.

## Access control

The [Caddyfile](config/caddy/Caddyfile) applies these rules on port 8427:

| Request | Result |
| --- | --- |
| Has an `Authorization` header with a valid login | Written to VictoriaLogs. The login decides the endpoint: `vector_user` goes to `/insert/jsonline`, `docker_user` to `/insert/loki/api/v1/push` |
| Has an `Authorization` header with an invalid login | `401` |
| No login, from an address not on the allowlist | `403` |
| No login, from an allowed address | Read routes only. Paths containing `..` get `400`, and insert, delete, and admin paths are never routed |

The read allowlist is `192.168.1.100`, `192.168.1.102`, `192.168.6.2`, `192.168.6.3`, the NUC at `192.168.1.217` for the `logs.*` route, and `172.16.0.0/12` for containers and processes on this host.

Grafana has no login of its own and gives anonymous users the Admin role, so `/grafana` only accepts requests from the NUC that carry the `X-Grafana-Proxy-Secret` header. Open it through `logs.*`, where the NUC's Caddy checks Authelia first and then adds the header. Any other request gets `403`, including from the rest of the allowlist and from anything on the NUC without the secret. Authelia's access rules decide who needs to log in on `logs.*`, so a bypass rule there also skips the login for Grafana.

The secret is the `grafana_proxy_secret` field in `DockerSecrets/logging-stack`, used by this stack and [nuc/proxy](../../nuc/proxy). Use a value with no quotes or `*`, such as the output of `openssl rand -hex 32`. It crosses the LAN over plain HTTP, like the shippers' logins. To change it, update the field and run this on the NUC first, then on the Pi:

```bash
# NUC, in nuc/proxy
docker compose up -d --force-recreate locket caddy
# Raspberry Pi, in rpi/logging-stack
docker compose up -d --force-recreate locket caddy
```

Grafana returns `403` between the two restarts.

After changing the network or Docker setup, confirm the allowlist still works by running this from a LAN host that isn't on the list. It should print `403`. Any other result means Caddy isn't seeing real client addresses, and reads may be open to the whole LAN:

```bash
curl -s -o /dev/null -w '%{http_code}\n' http://<rpi-lan-ip>:8427/vl/select/logsql/query
```

### Generating password hashes

Caddy stores bcrypt hashes rather than passwords. Clients keep sending the plaintext `vector_password` and `docker_password`. Generate each hash by entering the password at the prompt, then save the output to the matching `_hash` field:

```bash
docker run --rm -it caddy:2.11.7-alpine caddy hash-password
```

When you change a password, update its hash and run `docker compose up -d --force-recreate locket caddy`.

## Data and persistence

- Grafana data is stored in the grafanadata volume
- VictoriaLogs data is stored in the vldata volume
- VictoriaMetrics data is stored in the vmdata volume
- Secret material is written to a tmpfs-backed volume for runtime use

## How the pieces fit together

- Logs and metrics are collected and stored by VictoriaLogs and VictoriaMetrics
- Grafana connects to these backends using the provisioned datasource configuration
- Caddy routes outside requests and vmalert's queries to the right Victoria backend. Grafana connects to the backends directly
- vmalert evaluates rules and sends alerts to Alertmanager
- Alertmanager currently routes everything to a `blackhole` receiver with no notification destination. [TODO] Configure and test the intended delivery channel.

## Useful maintenance commands

Restart the stack:

```bash
docker compose restart
```

Stop and remove the stack:

```bash
docker compose down
```

## Notes

- Grafana is configured to use VictoriaLogs as a datasource.
- Secret values such as Grafana domain settings are loaded from the temporary secret store at runtime.
- The stack depends on the external proxy Docker network.
- The Docker and Jellyfin setup directories provide additional log shipping options for sending data into VictoriaLogs.
- VictoriaMetrics currently scrapes itself, VictoriaLogs, and vmalert every 10 seconds. This does not establish monitoring coverage of every stack.
