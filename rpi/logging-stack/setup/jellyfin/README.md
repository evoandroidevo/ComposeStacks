# Vector setup for Jellyfin logging

This guide installs Vector on Debian-based Linux systems, copies the sample configuration into the correct location, and enables the Vector systemd service.

## 1. Install Vector

On Debian/Ubuntu, install the Vector package from the official repository.

```bash
curl -1sLf 'https://repositories.timber.io/public/vector/cfg/setup/bash.deb.sh' \
  | sudo -E bash

sudo apt-get update
sudo apt-get install -y vector
```

## 2. Copy the configuration

Copy the sample configuration file into Vector's default config directory:

```bash
sudo mkdir -p /etc/vector
sudo cp /path/to/compose-stacks/local/logging-stack/setup/jellyfin/vector-config.yaml /etc/vector/vector.yaml
```

<details>
  <summary>If you are already in the repository root, you can use:</summary>

```bash
sudo mkdir -p /etc/vector
sudo cp ./local/logging-stack/setup/jellyfin/vector-config.yaml /etc/vector/vector.yaml
```

</details>

## 3. Validate the configuration

Test the configuration before starting Vector:

```bash
vector validate --config /etc/vector/vector.yaml
```

## 4. Enable and start the service

Enable and start Vector with systemd:

```bash
sudo systemctl daemon-reload
sudo systemctl enable vector
sudo systemctl start vector
```

Check the service status:

```bash
sudo systemctl status vector
```

## 5. View logs

If needed, view Vector logs with:

```bash
sudo journalctl -u vector -f
```

## Notes

- Adjust the file paths in the config if your Jellyfin logs are stored somewhere other than `/var/log/jellyfin/`.
- If you use a different config filename, update the service or command accordingly.
