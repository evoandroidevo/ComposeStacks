# Loki logging driver setup

> [!NOTE]
> The [Raspberry Pi](../../../vector) and [NUC](../../../../nuc/vector) now ship container logs with Vector. Use this setup only on hosts that haven't moved to Vector.

Use this setup when you want the Docker daemon to send container logs to a victorialogs endpoint.

## Migrating from the Loki driver

Running both ships every line twice, so remove the driver when you start Vector on a host:

1. In `/etc/docker/daemon.json`, replace the `loki` settings with a local driver and rotation policy:

   ```json
   {
     "log-driver": "json-file",
     "log-opts": {
       "max-size": "10m",
       "max-file": "3"
     }
   }
   ```

2. Restart Docker with `sudo systemctl restart docker`. This restarts containers unless `live-restore` is enabled.
3. Existing containers keep the driver they were created with, so recreate each stack with `docker compose up -d --force-recreate`.
4. Once no container uses the driver, remove the plugin with `sudo docker plugin disable loki` and `sudo docker plugin rm loki`.

## Requirements

- Docker Engine installed and running
- Root or sudo access to edit the Docker daemon configuration
- A reachable vicotrialogs endpoint, such as `http://<victorialogs-host>:9428/insert/loki/api/v1/push`
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
    "loki-url": "https://dockeruser:password@logs.domain.tld/",
    "loki-batch-size": "400",
    "loki-retries": "5",
    "loki-timeout": "10s"
  }
}
```
> [!NOTE]
> the above settings is how the logging stack's Caddy is configured to proxy based on user to the `insert/loki/api/v1/push` path
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
