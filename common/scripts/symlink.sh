#!/bin/sh
# Ensure `config.xml` is a symlink to `/run/secret/$PATH/config.xml`.
# If `config.xml` doesn't exist or is not a symlink, create/replace it.
# Usage: symlink.sh [--user USER] [--group GROUP] PATH...

set -eu

usage() {
	printf 'Usage: %s [--user USER] [--group GROUP] PATH...\n' "${0##*/}" >&2
}

if [ "$#" -eq 0 ]; then
	usage
	exit 2
fi

file=config.xml
owner_spec=
owner_user=
owner_group=

while [ "$#" -gt 0 ]; do
	case "$1" in
		--user)
			if [ "$#" -lt 2 ]; then
				printf 'Missing value for --user\n' >&2
				usage
				exit 2
			fi
			owner_user=$2
			shift 2
			;;
		--group)
			if [ "$#" -lt 2 ]; then
				printf 'Missing value for --group\n' >&2
				usage
				exit 2
			fi
			owner_group=$2
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
			printf 'Unknown option: %s\n' "$1" >&2
			usage
			exit 2
			;;
		*)
			break
			;;
	esac
done

if [ -n "$owner_user" ]; then
	owner_spec=$owner_user
fi
if [ -n "$owner_group" ]; then
	if [ -n "$owner_spec" ]; then
		owner_spec="$owner_spec:$owner_group"
	else
		owner_spec=":$owner_group"
	fi
fi

if [ "$#" -eq 0 ]; then
	printf 'No PATH arguments supplied\n' >&2
	usage
	exit 2
fi

print_path_info() {
	path=$1
	if [ -e "$path" ] || [ -L "$path" ]; then
		ls -ld "$path" 2>/dev/null || true
	else
		printf '%s: does not exist\n' "$path"
	fi
}

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

	file="$path/config.xml"
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
		if [ -n "$owner_spec" ]; then
			if ! chown -h "$owner_spec" "$file" 2>/dev/null; then
				printf 'Could not set ownership %s on %s\n' "$owner_spec" "$file" >&2
				exit_status=1
			fi
		fi

	else
		# Not a symlink (may exist or not). Fail if the supplied path does not exist.
		if [ ! -d "$path" ]; then
			printf '%s: path does not exist\n' "$arg" >&2
			exit_status=1
			continue
		fi

		file_dir=$(dirname "$file")
		if [ ! -d "$file_dir" ]; then
			printf '%s: path does not exist\n' "$arg" >&2
			exit_status=1
			continue
		fi

		if [ -e "$file" ] && [ ! -L "$file" ]; then
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
			printf 'Current working directory info:\n' >&2
			print_path_info "." >&2
			printf 'Target file info:\n' >&2
			print_path_info "$file" >&2
			exit_status=1
		fi
		if [ -n "$owner_spec" ]; then
			if ! chown -h "$owner_spec" "$file" 2>/dev/null; then
				printf 'Could not set ownership %s on %s\n' "$owner_spec" "$file" >&2
				exit_status=1
			fi
		fi
	fi
done

exit $exit_status
