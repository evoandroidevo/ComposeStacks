# Logging Stack

This stack provides a lightweight observability setup with Grafana, VictoriaLogs, VictoriaMetrics, vmauth, vmalert, and Alertmanager.

## Services

- grafana: web UI for dashboards and log/metric exploration
- victorialogs: stores and serves logs
- victoriametrics: stores and serves metrics
- vmauth: routes requests between VictoriaMetrics and VictoriaLogs
- vmalert: evaluates alerting and recording rules
- alertmanager: handles alert notifications
- locket: injects secrets from 1Password into the stack at runtime

## Requirements

- Docker and Docker Compose installed
- An 1Password token file available at /etc/op/token
- Configuration files present under ./config/
- External Docker networks named proxy and logging-network

## Start the stack

From this directory, run:

```bash
docker compose up -d
```

To view logs:

```bash
docker compose logs -f
```

## Notes

- Grafana is configured to use VictoriaLogs as a datasource.
- Secret values such as Grafana domain settings are loaded from the temporary secret store.
- Persistent data is stored in Docker volumes for Grafana, VictoriaLogs, and VictoriaMetrics.
