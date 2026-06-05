#!/usr/bin/env bash

set -Eeuo pipefail

# Backup directories
SOURCE_DIRS=(
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

# Check if destination exists
if [ -z "${1:-}" ]; then
	echo "usage: $0 [BACKUP_DIR]" >&2
	exit 1
fi

BACKUP_DIR=$(realpath "$1")

if [ ! -d "$BACKUP_DIR" ]; then
	echo "$0: backup directory '$BACKUP_DIR' does not exist" >&2
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
	rsync -aPh --delete "$dir" "${BACKUP_DIR}/"
done
