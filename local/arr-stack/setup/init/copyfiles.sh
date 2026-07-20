#!/bin/sh
set -eu

USER=""
GROUP=""
RUN_ONCE_FLAG="${RUN_ONCE_FLAG:-}"

usage() {
    echo "Usage: $0 --user <user> --group <group> <source1> [source2 ...]" >&2
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

FIRST_SRC="$1"
case "$FIRST_SRC" in
    /run/secret/*/config.xml)
        ;;
    *)
        echo "Error: Source path '$FIRST_SRC' must be in the form /run/secret/<path>/config.xml." >&2
        exit 1
        ;;
esac

FIRST_DEST="/${FIRST_SRC#/run/secret/}"
FIRST_DEST_DIR=$(dirname "$FIRST_DEST")
RUN_ONCE_FLAG="${RUN_ONCE_FLAG:-$FIRST_DEST_DIR/.copyfiles.done}"

if [ -f "$RUN_ONCE_FLAG" ]; then
    echo "Run-once flag '$RUN_ONCE_FLAG' exists; skipping copyfiles script."
    exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root to change file ownership." >&2
    exit 1
fi

for SRC in "$@"; do
    case "$SRC" in
        /run/secret/*/config.xml)
            ;;
        *)
            echo "Error: Source path '$SRC' must be in the form /run/secret/<path>/config.xml." >&2
            exit 1
            ;;
    esac

    DEST="/${SRC#/run/secret/}"
    DEST_DIR=$(dirname "$DEST")

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
