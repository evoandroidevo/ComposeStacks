#!/bin/sh
set -e

USER=""
GROUP=""

while getopts "u:g:" opt; do
    case "$opt" in
        u) USER="$OPTARG" ;;
        g) GROUP="$OPTARG" ;;
        *) echo "Usage: $0 -u <user> -g <group> <path1> [path2 ...]" >&2; exit 1 ;;
    esac
done

shift $((OPTIND - 1))

if [ -z "$USER" ] || [ -z "$GROUP" ] || [ "$#" -lt 1 ]; then
    echo "Error: Missing required arguments." >&2
    echo "Usage: $0 -u <user> -g <group> <path1> [path2 ...]" >&2
    exit 1
fi

# 1. Global Check: Must be root to use chown for another user/group
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root to change file ownership." >&2
    exit 1
fi

for p in "$@"; do
    SRC="/run/secret/$p/config.xml"
    DEST_DIR="/$p"
    DEST="$DEST_DIR/config.xml"

    # 2. Check source existence
    if [ ! -f "$SRC" ]; then
        echo "Error: Source secret file '$SRC' does not exist." >&2
        exit 1
    fi

    # 3. Check source size
    if [ ! -s "$SRC" ]; then
        echo "Error: Source secret file '$SRC' is 0 bytes." >&2
        exit 1
    fi

    # 4. Permission Check: Current user must have READ permission on source
    if [ ! -r "$SRC" ]; then
        echo "Error: Current user lacks READ permission for '$SRC'." >&2
        exit 1
    fi

    # 5. Target Check: Ensure the target directory exists
    if [ ! -d "$DEST_DIR" ]; then
        echo "Error: Destination directory '$DEST_DIR' does not exist." >&2
        exit 1
    fi

    # 6. Permission Check: Current user must have WRITE/EXECUTE permissions on destination directory
    if [ ! -w "$DEST_DIR" ] || [ ! -x "$DEST_DIR" ]; then
        echo "Error: Current user lacks WRITE or EXECUTE permissions for directory '$DEST_DIR'." >&2
        exit 1
    fi

    # 7. Permission Check: If target file already exists, current user must have WRITE permission to overwrite it
    if [ -f "$DEST" ] && [ ! -w "$DEST" ]; then
        echo "Error: Current user lacks WRITE permission to overwrite existing file '$DEST'." >&2
        exit 1
    fi

    # Execute operations safely after all checks pass
    cp "$SRC" "$DEST"
    chown "$USER:$GROUP" "$DEST"

    echo "Successfully copied and set ownership for $DEST"
done
