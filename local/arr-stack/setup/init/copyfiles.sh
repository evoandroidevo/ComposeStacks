#!/bin/sh
set -eu

USER=""
GROUP=""
RUN_ONCE_FLAG="${RUN_ONCE_FLAG:-}"

usage() {
    echo "Usage: $0 --user <user> --group <group> </path|/run/secret/path/config.xml> [...]" >&2
}

resolve_paths() {
    case "$1" in
        /run/secret/*/config.xml)
            SRC="$1"
            DEST="/${1#/run/secret/}"
            ;;
        /*)
            SRC="/run/secret${1}/config.xml"
            DEST="$1/config.xml"
            ;;
        *)
            echo "Error: Path '$1' must be either /<path> or /run/secret/<path>/config.xml." >&2
            exit 1
            ;;
    esac

    DEST_DIR=$(dirname "$DEST")
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --user)
            [ "$#" -ge 2 ] || { echo "Error: --user requires a value." >&2; usage; exit 1; }
            USER="$2"
            shift 2
            ;;
        --group)
            [ "$#" -ge 2 ] || { echo "Error: --group requires a value." >&2; usage; exit 1; }
            GROUP="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Error: Unknown option '$1'." >&2
            usage
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

if [ -z "$USER" ] || [ -z "$GROUP" ] || [ "$#" -lt 1 ]; then
    echo "Error: Missing required arguments." >&2
    usage
    exit 1
fi

resolve_paths "$1"
RUN_ONCE_FLAG="${RUN_ONCE_FLAG:-$DEST_DIR/.copyfiles.done}"

if [ -f "$RUN_ONCE_FLAG" ]; then
    echo "Run-once flag '$RUN_ONCE_FLAG' exists; skipping copyfiles script."
    exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root to change file ownership." >&2
    exit 1
fi

for ARG in "$@"; do
    resolve_paths "$ARG"

    if [ ! -f "$SRC" ]; then
        echo "Error: Source secret file '$SRC' does not exist." >&2
        exit 1
    fi

    if [ ! -s "$SRC" ]; then
        echo "Error: Source secret file '$SRC' is 0 bytes." >&2
        exit 1
    fi

    if [ ! -r "$SRC" ]; then
        echo "Error: Current user lacks READ permission for '$SRC'." >&2
        exit 1
    fi

    if [ ! -d "$DEST_DIR" ]; then
        echo "Error: Destination directory '$DEST_DIR' does not exist." >&2
        exit 1
    fi

    if [ ! -w "$DEST_DIR" ] || [ ! -x "$DEST_DIR" ]; then
        echo "Error: Current user lacks WRITE or EXECUTE permissions for directory '$DEST_DIR'." >&2
        exit 1
    fi

    if [ -e "$DEST" ] && [ ! -w "$DEST" ]; then
        echo "Error: Current user lacks WRITE permission to overwrite existing file '$DEST'." >&2
        exit 1
    fi

    if ! cp "$SRC" "$DEST"; then
        echo "Error: Failed to copy '$SRC' to '$DEST'." >&2
        exit 1
    fi

    if ! chown "$USER:$GROUP" "$DEST"; then
        echo "Error: Failed to set ownership for '$DEST'." >&2
        exit 1
    fi

    echo "Successfully copied and set ownership for $DEST"
done

if ! touch "$RUN_ONCE_FLAG"; then
    echo "Error: Failed to write run-once flag '$RUN_ONCE_FLAG'." >&2
    exit 1
fi
