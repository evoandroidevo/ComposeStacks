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

Example:

```yaml
services:
  example-app:
    image: your-image:latest
    entrypoint: ["/init.sh", "-f", "/run/secrets/locket/app.env"]
    command: ["/your/container/entrypoint"]
```

In this pattern:

- `init.sh` reads `/run/secrets/locket/app.env`
- It exports the variables into the process environment
- It then execs `/your/container/entrypoint`

### Example with a mounted env file

```yaml
services:
  example-app:
    image: your-image:latest
    entrypoint: ["/init.sh", "-f", "/tmp/app.env"]
    command: ["/usr/local/bin/start-app"]
    volumes:
      - ./config/app.env:/tmp/app.env:ro
```

### Notes

- The script uses POSIX `sh`, so it is compatible with minimal container images.
- If no command is provided after the env file, the script exits successfully after loading the environment.
- The script expects one variable per line in the form `KEY=VALUE`.

### Example env file

```env
DATABASE_URL=postgres://user:pass@db:5432/app
API_KEY=super-secret
```
