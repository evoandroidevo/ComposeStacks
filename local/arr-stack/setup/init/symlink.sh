#!/bin/sh
# Ensure `config.xml` is a symlink to `/run/secret/$PATH/config.xml`.
# If `config.xml` doesn't exist or is not a symlink, create/replace it.
# Usage: symlink.sh PATH...

set -eu

if [ "$#" -eq 0 ]; then
	printf 'Usage: %s PATH...\n' "${0##*/}" >&2
	exit 2
fi

file=config.xml

resolve_link() {
	target=$1
	if command -v readlink >/dev/null 2>&1; then
		if readlink -f / >/dev/null 2>&1; then
			readlink -f "$target" 2>/dev/null && return 0
		fi
	fi
	if command -v realpath >/dev/null 2>&1; then
		realpath "$target" 2>/dev/null && return 0
	fi
	t=$(readlink "$target" 2>/dev/null) || return 1
	case "$t" in
		/*) printf '%s\n' "$t" ;;
		*) printf '%s\n' "$(cd "$(dirname "$target")" >/dev/null 2>&1 && pwd)/$t" ;;
	esac
}

exit_status=0
for arg in "$@"; do
	path=$arg
	# strip leading slashes
	while [ "${path#/}" != "$path" ]; do path=${path#/}; done
	# strip trailing slashes
	while [ "${path%/}" != "$path" ]; do path=${path%/}; done

	if [ -z "$path" ]; then
		printf 'Skipping empty path argument\n' >&2
		exit_status=2
		continue
	fi

	expected="/run/secret/$path/config.xml"

	if [ -L "$file" ]; then
		# resolve and compare
		link_target=$(resolve_link "$file") || link_target=$(readlink "$file" 2>/dev/null || true)
		case "$link_target" in
			/*) ;;
			*) link_target="$(pwd)/$link_target" ;;
		esac
		if [ "$link_target" = "$expected" ]; then
			printf '%s: OK -> %s\n' "$arg" "$link_target"
		else
			printf '%s: MISMATCH (points to %s, expected %s)\n' "$arg" "$link_target" "$expected" >&2
			exit_status=1
		fi

	else
		# Not a symlink (may exist or not). Create parent dir for target if possible.
		parent_dir=$(dirname "$expected")
		if [ ! -d "$parent_dir" ]; then
			if ! mkdir -p "$parent_dir" 2>/dev/null; then
				printf 'Warning: could not create %s (permissions?)\n' "$parent_dir" >&2
			fi
		fi

		if [ -e "$file" ]; then
			# Backup existing file before replacing
			ts=$(date +%s 2>/dev/null || printf '%s' "$(date)")
			mv "$file" "${file}.$ts.orig" 2>/dev/null || rm -f "$file" 2>/dev/null || true
			printf 'Backed up existing %s to %s.%s.orig\n' "$file" "$file" "$ts"
		fi

		# Create symlink pointing to the expected target
		if ln -s "$expected" "$file" 2>/dev/null; then
			printf '%s: CREATED -> %s\n' "$arg" "$expected"
		else
			printf '%s: FAILED to create symlink -> %s\n' "$arg" "$expected" >&2
			exit_status=1
		fi
	fi
done

exit $exit_status
