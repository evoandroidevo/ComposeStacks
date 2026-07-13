# Logging Stack

This stack provides a lightweight observability environment for logs and metrics using Grafana, VictoriaLogs, VictoriaMetrics, vmauth, vmalert, and Alertmanager. It is intended to collect, store, and visualize operational data for the local services in this repository.

## What this stack provides

- Grafana for dashboards and log/metric exploration
- VictoriaLogs for storing and querying logs
- VictoriaMetrics for storing and querying metrics
- vmauth as a routing layer between Grafana and the Victoria products
- vmalert and Alertmanager for alert evaluation and delivery
- locket for injecting runtime secrets from 1Password

## Services

- grafana: web UI for dashboards and log/metric exploration
- victorialogs: stores and serves logs internally on port 9428
- victoriametrics: stores and serves metrics internally on port 8428
- vmauth: routes requests to the appropriate backend based on the request path
- vmalert: evaluates alerting and recording rules
- alertmanager: handles alert notifications
- locket: injects secrets from 1Password into the stack at runtime

## Requirements

- Docker and Docker Compose installed
- An 1Password token file available at /etc/op/token
- Configuration files present under ./config/
- External Docker networks named proxy and logging-network
- Valid secret values for Grafana domain settings in your 1Password store

## Directory layout

- [compose.yaml](compose.yaml) — main stack definition and service wiring
- [config/](config) — Grafana provisioning, datasource config, alert rules, and vmauth config
- [setup/docker](setup/docker) — Docker log shipping configuration for forwarding container logs to VictoriaLogs
- [setup/jellyfin](setup/jellyfin) — Vector-based Jellyfin log forwarding and setup notes

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

## Data and persistence

- Grafana data is stored in the grafanadata volume
- VictoriaLogs data is stored in the vldata volume
- VictoriaMetrics data is stored in the vmdata volume
- Secret material is written to a tmpfs-backed volume for runtime use

## How the pieces fit together

- Logs and metrics are collected and stored by VictoriaLogs and VictoriaMetrics
- Grafana connects to these backends using the provisioned datasource configuration
- vmauth routes requests between the Victoria backends for alerting and querying
- vmalert evaluates rules and sends alerts to Alertmanager

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
