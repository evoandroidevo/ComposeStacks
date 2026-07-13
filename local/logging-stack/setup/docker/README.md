# Loki logging driver setup

Use this setup when you want the Docker daemon to send container logs to a victorialogs endpoint.

## Requirements

- Docker Engine installed and running
- Root or sudo access to edit the Docker daemon configuration
- A reachable vicotrialogs endpoint, such as `http://<victorialogs-host>:9428/loki/api/v1/push`
- Network access from the Docker host to the victorialogs server

## Install the plugin

Install the Loki Docker logging driver plugin:

```bash
sudo docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions
```

## Configure the Docker daemon

Create or update `/etc/docker/daemon.json` with the following settings:

```json
{
  "log-driver": "loki",
  "log-opts": {
    "loki-url": "http://<victorialogs-host>:9428/loki/api/v1/push",
    "loki-batch-size": "400",
    "loki-retries": "5",
    "loki-timeout": "10s"
  }
}
```

## Restart Docker

Reload the Docker daemon configuration and restart Docker:

```bash
sudo systemctl restart docker
```

## Verify

Confirm the plugin is installed and Docker is using the logging driver:

```bash
sudo docker plugin ls
sudo docker info | grep -i logging
```

If you want to test it, run a temporary container and check that logs appear in your victorialogs instance.
