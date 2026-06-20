# Logging Stack

Services: Grafana (Alloy), Loki, InfluxDB

Run:

```bash
# from this directory
docker compose up -d

# or override Grafana image (use grafana/grafana if you don't have grafana/alloy)
GRAFANA_IMAGE=grafana/grafana:latest docker compose up -d
```

Environment variables (optional):

- `GRAFANA_IMAGE` — image to use for Grafana (default: `grafana/alloy:latest`)
- `GF_SECURITY_ADMIN_PASSWORD` — Grafana admin password (default: `grafana`)
- `INFLUXDB_INIT_*` — InfluxDB init variables (see compose.yaml for names)

Grafana: http://localhost:3000
Loki: http://localhost:3100
InfluxDB: http://localhost:8086

Loki config is at `loki/config/local-config.yaml`.

Grafana provisioning and dashboards:

- Datasources are provisioned from `grafana/provisioning/datasources/datasources.yaml`.
- Dashboard provider is at `grafana/provisioning/dashboards/dashboards.yaml` and loads JSON dashboards from `grafana/dashboards`.

Change the InfluxDB org/token in the datasource file to match your environment if needed.
