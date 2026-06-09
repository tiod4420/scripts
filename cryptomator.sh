#!/usr/bin/env bash

set -Eeuo pipefail

# Backup directories
SOURCE_DIRS=(
	$HOME/Backups
	$HOME/Documents
)

BACKUP_DIR=${1:-$HOME/.local/share/Cryptomator/mnt/Safe}

# Check if safe exists and is mounted
if [ ! -d "$BACKUP_DIR" ]; then
	echo "$0: Cryptomator safe '$BACKUP_DIR' does not exist" >&2
	exit 1
fi

if ! mountpoint -q "$BACKUP_DIR"; then
	echo "$0: Cryptomator safe '$BACKUP_DIR' is not a mountpoint" >&2
	exit 1
fi

# Backup directories and delete extra files
for dir in "${SOURCE_DIRS[@]}"; do
	if [ ! -d "$dir" ]; then
		echo "$0: missing directory '$dir'" >&2
		continue
	fi

	# Remove trailing '/' from path
	dir=$(realpath "$dir")

	# rsync directory (trailing '/' needed)
	rsync -aPh --delete "$dir" "$BACKUP_DIR/"
done
