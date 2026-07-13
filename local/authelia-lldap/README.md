# Authelia + LLDAP

This stack provides a self-contained authentication and identity management environment for local development and small deployments. It runs Authelia as the primary authentication provider, a lightweight LLDAP directory for storing users and groups, PostgreSQL as Authelia's backing store, and Redis for session/cache support. Secrets are injected at runtime via `locket` so sensitive values are not persisted in the repository.

## Services

- `locket`: materializes secret templates from 1Password into a tmpfs-backed secret store
- `authelia-db`: PostgreSQL database used by Authelia for configuration and state
- `llldap`: lightweight LDAP server for users and groups consumed by Authelia
- `authelia`: the authentication server (2FA, OIDC, reverse-proxy compatible)
- `redis`: in-memory cache for sessions and rate-limiting

## Requirements

- Docker and Docker Compose
- An 1Password token file available at `/etc/op/token` with access to configured secret templates
- Secret template files present under `./config/` (templates consumed by `locket`)
- External Docker network `proxy` for reverse-proxy integration

## Configuration

- Put your secret template files in `./config/` and reference the same secret paths in your 1Password vault that `locket` expects.
- Key runtime files produced by `locket` are written into the `secrets-store-auth` tmpfs volume and made available to Authelia and LLDAP via mounts.
- Authelia settings (configuration.yml) live in the generated secret files; modify the template in `./config` and let `locket` materialize the runtime configuration.

## Start / Stop

Bring the stack up:

```bash
docker compose up -d
```

Stop the stack:

```bash
docker compose down
```

Follow logs for troubleshooting:

```bash
docker compose logs -f
```

To restart a single service (e.g., Authelia) without bringing the whole stack down:

```bash
docker compose restart authelia
```

## Secrets workflow

- `locket` reads `/etc/op/token` to authenticate to 1Password and renders templates from `./config` into the tmpfs-backed `secrets-store-*` volume.
- Secrets are mounted read-only into containers; they are not committed to this repository.
- To update a secret, update the template in `./config` and restart `locket` (or the stack) so it can materialize the new values.

## Reverse proxy integration

- This stack expects to be connected to the external `proxy` Docker network so a reverse proxy (Caddy, Traefik, etc.) can route requests to Authelia.
- Ensure the reverse proxy is configured to forward authentication and callback URIs to Authelia as defined in your `authelia` config template.

## LDAP provisioning

- The LLDAP service provides a lightweight LDAP directory for Authelia to query users and groups.
- If you need to add users, update the LLDAP template under `./config/lldap` (if present) or the appropriate provisioning file and restart the stack to apply changes.

## Backups and persistence

- PostgreSQL data is persisted to a Docker volume declared in the compose file. Backups can be performed by running `pg_dump` inside the `authelia-db` container or mounting the volume to a helper container.

Example backup command:

```bash
docker compose exec authelia-db pg_dump -U <user> -Fc <dbname> > authelia-$(date +%F).dump
```

## Common troubleshooting

- Authelia fails to start: check `docker compose logs authelia` for missing secret files produced by `locket`.
- Database connection errors: ensure `authelia-db` is healthy and credentials in the secret templates match the database.
- LDAP lookup failures: verify `lldap` is running and accessible from the `authelia` container; check network attachments.

## Maintenance tips

- Rotate secrets by updating the templates in `./config` and restarting `locket`.

## See also

- The top-level `local/README.md` for an overview of all local stacks
- `./config/` in this directory for the templates consumed by `locket`
