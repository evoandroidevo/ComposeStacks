#!/bin/sh

set -eu

usage() {
	echo "Usage: $0 --user USER --group GROUP /path1 [/path2 ...]"
	echo ""
	echo "Applies USER:GROUP ownership to each provided path recursively."
}

USER_NAME=""
GROUP_NAME=""

while [ "$#" -gt 0 ]; do
	case "$1" in
		--user)
			[ "$#" -ge 2 ] || {
				echo "Error: --user requires a value" >&2
				usage
				exit 1
			}
			USER_NAME="$2"
			shift 2
			;;
		--group)
			[ "$#" -ge 2 ] || {
				echo "Error: --group requires a value" >&2
				usage
				exit 1
			}
			GROUP_NAME="$2"
			shift 2
			;;
		--user=*)
			USER_NAME="${1#--user=}"
			shift
			;;
		--group=*)
			GROUP_NAME="${1#--group=}"
			shift
			;;
		--help|-h)
			usage
			exit 0
			;;
		--)
			shift
			break
			;;
		-* )
			echo "Error: unknown option '$1'" >&2
			usage
			exit 1
			;;
		*)
			break
			;;
	esac
done

[ -n "$USER_NAME" ] || {
	echo "Error: --user is required" >&2
	usage
	exit 1
}

[ -n "$GROUP_NAME" ] || {
	echo "Error: --group is required" >&2
	usage
	exit 1
}

[ "$#" -gt 0 ] || {
	echo "Error: at least one path is required" >&2
	usage
	exit 1
}

OWNER="$USER_NAME:$GROUP_NAME"

for path in "$@"; do
	if [ ! -e "$path" ]; then
		echo "Warning: path not found, skipping '$path'" >&2
		continue
	fi

	echo "Applying ownership $OWNER to $path"
	chown -R "$OWNER" "$path"
done
