# Authelia + LLDAP

This stack runs Authelia for authentication, LLDAP for identity management, PostgreSQL for the Authelia database, and Redis for session/cache support.

## Services

- locket: populates secret files from 1Password templates into a temporary secret store.
- authelia-db: PostgreSQL instance used by Authelia.
- lldap: lightweight LDAP server for user and group management.
- authelia: main authentication service.
- redis: backing cache for Authelia.

## Requirements

- Docker and Docker Compose installed
- An 1Password token file available at /etc/op/token
- Secret template files present under ./config/
- An external Docker network named proxy

## Start the stack

From this directory, run:

```bash
docker compose up -d
```

To follow logs:

```bash
docker compose logs -f
```

## Notes

- The stack uses a tmpfs-backed volume for generated secrets.
- Authelia and LLDAP both read their runtime configuration from the mounted secret store.
- The services are wired to the external proxy network for reverse proxy integration.
