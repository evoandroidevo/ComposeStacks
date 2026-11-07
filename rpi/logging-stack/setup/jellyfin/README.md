# Jellyfin host logging

Ships the Jellyfin server log and the Jellyfin Enhanced plugin log from `/var/log/jellyfin` to VictoriaLogs through the logging stack's Caddy. Vector runs as a native package on the Jellyfin host. Run these commands as root on that host.

## 1. Install Vector

```bash
bash -c "$(curl -L https://setup.vector.dev)"
apt-get install -y vector
```

## 2. Copy the configuration

The Jellyfin host doesn't have a copy of this repository, so run this from the repository root on another machine:

```bash
scp rpi/logging-stack/setup/jellyfin/vector.yaml root@<jellyfin-ip>:/etc/vector/vector.yaml
```

The config sends logs to `http://192.168.1.236:8427/`, which sends the credentials and logs unencrypted. `logs.*` is the HTTPS alternative, but it's behind Authelia, so it only works if Authelia lets this host through.

## 3. Set the credentials

Vector reads each credential from its own file in `/etc/vector/secrets`. Use the same `vector_user` and `vector_password` values as the other hosts. `read` keeps the values out of your shell history:

```bash
install -d -o root -g vector -m 750 /etc/vector/secrets
read -r VECTOR_USER
read -rs VECTOR_PASSWORD
printf '%s\n' "$VECTOR_USER" > /etc/vector/secrets/vector_user
printf '%s\n' "$VECTOR_PASSWORD" > /etc/vector/secrets/vector_password
unset VECTOR_USER VECTOR_PASSWORD
chown root:vector /etc/vector/secrets/*
chmod 640 /etc/vector/secrets/*
```

## 4. Check access to the logs

```bash
ls -ld /var/log/jellyfin
runuser -u vector -- ls /var/log/jellyfin
```

If the second command fails, add the `vector` user to the directory's group, for example `usermod -aG jellyfin vector`, and run it again.

## 5. Validate and start

```bash
runuser -u vector -- vector validate --no-environment --resolve-secrets /etc/vector/vector.yaml
systemctl enable --now vector
systemctl status vector
```

To follow Vector's own logs:

```bash
journalctl -u vector -f
```

## 6. Verify

Run this on the Raspberry Pi. It should return recent lines:

```bash
curl -s http://localhost:8427/vl/select/logsql/query -d 'query=_time:5m stack:="jellyfin" | limit 5'
```

## Log fields

| Field | Server log | Plugin log |
| --- | --- | --- |
| `host` | Jellyfin host's hostname | Jellyfin host's hostname |
| `stack` | `jellyfin` | `jellyfin` |
| `service` | `jellyfin` | `jellyfin-enhanced` |
| `level` | `INF`, `WRN`, `ERR` and so on, mapped to `info`, `warn`, `error` | `INFO`, `WARN`, `ERROR`, `DEBUG`, mapped the same way |
| `component` | A leading `[Name]` in the message, such as `Jellycheckr` | The plugin feature, such as `TagCache` or `CDN` |

`host`, `stack`, and `service` are the VictoriaLogs stream fields. Stack traces and other multi-line messages are kept together as one entry.

## Notes

- The plugin log has no time zone, so its timestamps are read as `America/Chicago`. Change `timezone` in `vector.yaml` if the server uses another zone.
- The server repeats most plugin messages, so `INFO` and `WARN` plugin lines appear twice, once per `service`. The plugin log also has `DEBUG` lines the server log doesn't.
- Upgrade with the host's normal `apt` updates. Vector is not pinned here, so review its release notes when it updates.
