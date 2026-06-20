#!/bin/sh

set -eu

usage() {
  cat <<EOF
Usage: $0 -f|--file <env-file> [--] [command...]

Load environment variables from a file and then exec the container's default command.

Options:
  -f, --file   Path to an env file containing KEY=VALUE lines
  --           End option parsing and pass remaining arguments as the command
EOF
}

ENV_FILE=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    -f|--file)
      shift
      if [ "$#" -eq 0 ]; then
        echo "Error: missing env file path." >&2
        usage
        exit 1
      fi
      ENV_FILE="$1"
      shift
      ;;
    --)
      shift
      break
      ;;
    -* )
      echo "Error: unknown option: $1" >&2
      usage
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

if [ -z "$ENV_FILE" ]; then
  echo "Error: env file is required." >&2
  usage
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: file '$ENV_FILE' not found." >&2
  exit 1
fi

# Load env variables from file.
# Supports lines of the form KEY=VALUE, ignores empty lines and comments.
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    ''|#*)
      continue
      ;;
  esac

  # Remove trailing CR if the file uses Windows line endings.
  line=$(printf '%s' "$line" | sed 's/\r$//')

  case "$line" in
    *=*)
      key=${line%%=*}
      value=${line#*=}
      export "$key=$value"
      ;;
    *)
      echo "Warning: skipping invalid env line: $line" >&2
      ;;
  esac
 done < "$ENV_FILE"

echo "Loaded environment from $ENV_FILE"

if [ "$#" -gt 0 ]; then
  exec "$@"
fi

# If no command is supplied, exit successfully.
exit 0
