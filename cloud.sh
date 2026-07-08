#!/usr/bin/env bash
#
# Backup list of directories to a directory

set -Eeuo pipefail

# Display error message, usage, and quit
error() {
	local msg=${1:-error}
	local ret=${2:-1}

	echo "$0: $msg" >&2

	exit $ret
}

# Backup directories
SOURCE_DIRS=(
	$HOME/Backups
	$HOME/Documents
)

DESTINATION_DIR=${1:-${CLOUD_BACKUP_DIR:-}}

# Check if destination dir exists
! [ -d "$DESTINATION_DIR" ] && error "'$DESTINATION_DIR': No such file or directory"

# Backup directories
for src in "${SOURCE_DIRS[@]}"; do
	# Check if source dir exists
	! [ -d "$src" ] && error "'$src': No such file or directory"

	# Resolve path and remove trailing '/'
	src=$(realpath "$src")

	# Rsync uses BSD convention
	# - rsync -r src dst: copy content of src into dst/src
	# - rsync -r src/ dst: copy content of src into dst
	rsync -aPh --delete "$src" "$DESTINATION_DIR"
done
