# Common scripts

This directory contains helper scripts used by the Compose stacks in this repository.

## init.sh

`init.sh` is a small entrypoint helper for Docker containers that cannot read environment variables from files directly. It loads values from a `.env`-style file, exports them into the current shell environment, and then executes the container's real entrypoint or command.

### What it does

- Accepts an env file path with `-f` or `--file`
- Reads `KEY=VALUE` pairs from the file
- Ignores empty lines and comments
- Removes Windows-style trailing carriage returns from values
- Exports the variables into the environment
- Executes the next command, if provided

### Why it exists

Some containers expect environment variables to be present in the process environment, but their image or entrypoint cannot read them from a mounted file directly. This script bridges that gap by loading values from a generated file and then handing off control to the container's actual command.

### Typical use in Docker Compose

A common pattern is to make the script the entrypoint, point it at a file created by another helper such as `locket`, and then pass the original container entrypoint/command as arguments.

Example: using locket sidecar mode for secrets

```yaml
services:
  locket:
    image: ghcr.io/bpbradley/locket:op
    user: "65532:1000" # OP (1pass cli) complains about file permissions if it doesnt start at 65532 user last i tested.
    container_name: locket-dockhand
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    command:
      - "--provider=op"
      - "--mode=park" # we use park since docker removes files created in a tmpfs volume if the container that creted them exits
      - "--inject-failure-policy=error" # We error out if there are issues with secret injection so apps dont start without secrets.
      - "--op-token=file:/run/secrets/op_token"
      - "--secret=encryption_key=ENCRYPTION_KEY={{ op://Vault/APP/encryption_key }}" # encryption_key is the filename that locket will use, ENCRYPTION_KEY={{ op://Vault/APP/encryption_key }} is the file contents with the environment variable name and the secret that is to be injected
    secrets:
      - op_token
    volumes:
      - secrets-store-example:/run/secrets/locket

  example-app:
    image: your-image:latest
    entrypoint: ["/init.sh", "-f", "/config/encryption_key"]
    command: ["/usr/local/bin/start-app"] # check the app's dockerfile ENTRYPOINT and CMD that you are using this init.sh script with to configure the command, if only ENTRYPOINT is used in the dockerfile copy it to command: in the compose file, if ENTRYPOINT and CMD are populated then combine them as an example here is how i have combined postgres's ENTRYPOINT ["docker-entrypoint.sh"] and CMD ["postgres"] to command: ["docker-entrypoint.sh", "postgres"]
    depends_op:
      locket:
        condition: service_healthy # Locket becomes healthy when all secrets have been injected into the files is has been configured for.
    user: 1000:1000
    volumes:
      - ./init.sh:/init.sh:ro # We have to mount the init.sh into the container that is going to be using it since its not builtin.
      - type: volume
        source: secrets-store-example
        target: /config/encryption_key
        read_only: true
        volume:
          subpath: encryption_key # We only mount the required encryption_key file into the container as read only from the temp secrets-store-example volume to prevent access to other secrets from other services if present.
volumes:
  secrets-store-example:
    driver: local
    driver_opts:
      driver_opts:
      type: tmpfs
      device: tmpfs
      o: uid=65532,gid=1000,mode=740 # Since example-app container is configured to start as user: 1000:1000 we set the group to gid 1000 so the init script can read it with our set permissions of -rwxr----- or can use 744 for -rwxr--r-- for global read access
secrets:
  op_token:
    file: /location/to/file # this is the location of the file that contains the 1pass token, the user locket runs under must have read permissions to this file.
```

In this pattern:

- `init.sh` reads `/run/secrets/locket/app.env`
- It exports the variables into the process environment
- It then execs `/your/container/entrypoint`

### Notes

- The script uses POSIX `sh`, so it is compatible with minimal container images.
- If no command is provided after the env file, the script exits successfully after loading the environment.
- The script expects one variable per line in the form `KEY=VALUE`.

### Example env file

```env
DATABASE_URL=postgres://user:pass@db:5432/app
API_KEY=super-secret
```
