#!/usr/bin/env bash

set -Eeuo pipefail

# Backup directories
BACKUP_DIRS=(
	${HOME}/Backups
	${HOME}/Documents
	${HOME}/Ebooks
	${HOME}/Education
	${HOME}/Games
	${HOME}/Music
	${HOME}/Pictures
	${HOME}/Scans
	${HOME}/Sync
	${HOME}/Videos
	${HOME}/Workspace
)

MOUNT_DIR=$(realpath "$1")

# Check if destination exists
if [ ! -d "$MOUNT_DIR" ]; then
	echo "$0: invalid directory $MOUNT_DIR" >&2
	exit 1
fi

# Backup directories and delete extra files
for dir in "${BACKUP_DIRS[@]}"; do
	if [ ! -d "$dir" ]; then
		echo "$0: missing directory $dir" >&2
		continue
	fi

	# Remove trailing '/' from path
	dir=$(realpath "$dir")

	# rsync directory (trailing '/' needed)
	rsync -aPh --delete "$dir" "${MOUNT_DIR}/"
done
