# Proxmox host logging

Ships the Proxmox host's systemd journal, PVE task logs, and non-routine API access logs to VictoriaLogs through the logging stack's Caddy. Successful `GET` requests in the access log are dropped because the web GUI polls the API constantly. Vector runs as a native package because Docker shouldn't be installed on the Proxmox host itself. Run these commands as root on the host.

## 1. Install Vector

```bash
bash -c "$(curl -L https://setup.vector.dev)"
apt-get install -y vector
```

## 2. Copy the configuration

The Proxmox host doesn't have a copy of this repository, so run this from the repository root on another machine:

```bash
scp rpi/logging-stack/setup/proxmox/vector.yaml root@<proxmox-ip>:/etc/vector/vector.yaml
```

## 3. Set the endpoint and credentials

In `/etc/vector/vector.yaml`, change `uri` to start with `http://<rpi-lan-ip>:8427/`, which sends the credentials and logs unencrypted. `logs.*` is the HTTPS alternative, but it's behind Authelia, so it only works if Authelia lets this host through.

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

## 4. Allow access to the PVE logs

`/var/log/pveproxy` is only accessible to its owner, so group membership doesn't help. Give Vector a read capability with a systemd drop-in, which survives Vector and Proxmox upgrades. The capability bypasses read permissions across the host, so the drop-in also blocks the most sensitive paths:

```bash
mkdir -p /etc/systemd/system/vector.service.d
cat > /etc/systemd/system/vector.service.d/10-read-logs.conf <<'EOF'
[Service]
AmbientCapabilities=CAP_DAC_READ_SEARCH
NoNewPrivileges=yes
ProtectHome=yes
InaccessiblePaths=-/root
InaccessiblePaths=-/etc/shadow
InaccessiblePaths=-/etc/ssh
InaccessiblePaths=-/etc/pve
EOF
systemctl daemon-reload
```

Vector can still read other files on the host, so add any other sensitive paths to the list.

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

Run this on the Raspberry Pi, replacing `<proxmox-hostname>` with the output of `hostname` on the Proxmox host. It should return recent lines:

```bash
curl -s http://localhost:8427/vl/select/logsql/query -d 'query=_time:5m host:<proxmox-hostname> source:journald | limit 5'
```

## Notes

- The package adds the `vector` user to the groups needed to read the journal. If Vector logs a journal permission error, run `usermod -aG systemd-journal vector` and restart the service.
- Upgrade with the host's normal `apt` updates. Vector is not pinned here, so review its release notes when it updates.
