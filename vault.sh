#!/usr/bin/env bash

set -Eeuo pipefail

# Backup and vault directories
SOURCE_DIRS=(
	${HOME}/Backups
	${HOME}/Documents
)

VAULT_DIR="${1:-${HOME}/Sync/Vault}"

# Mount and unmount functions
is_gocryptfs() {
	gocryptfs --info "$1" > /dev/null 2>&1
}

vault_mount() {
	local vault=$1
	local mount=$2

	if is_gocryptfs "$vault"; then
		gocryptfs "$vault" "$mount"
	else
		cryfs "$vault" "$mount"
	fi
}

vault_unmount() {
	local vault=$1
	local mount=$2

	# Check that we are mount point
	! mountpoint -q "$mount" && return 0

	if is_gocryptfs "$vault"; then
		fusermount -u "$mount"
	else
		cryfs-unmount "$mount"
	fi
}

cleanup() {
	local ret=$?

	# Disable exit on failure
	set +e

	# Unmount vault and wait a bit in case resource is busy
	vault_unmount "$VAULT_DIR" "$MOUNT_DIR"
	sync
	sleep 1

	# Delete mount directory
	[ -d "$MOUNT_DIR" ] && rmdir "$MOUNT_DIR"

	exit $ret
}

# Check if vault exists
if  [ ! -d "$VAULT_DIR" ]; then
	echo "$0: vault directory '${VAULT_DIR}' does not exist" >&2
	exit 1
fi

# Create mount directory and setup cleanup
MOUNT_DIR=$(mktemp --tmpdir --directory vault-mnt.XXXXXXXXXX)
trap cleanup EXIT

# Mount vault
vault_mount "$VAULT_DIR" "$MOUNT_DIR"

# Backup directories and delete extra files
for dir in "${SOURCE_DIRS[@]}"; do
	if [ ! -d "$dir" ]; then
		echo "$0: missing directory '$dir'" >&2
		continue
	fi

	# Remove trailing '/' from path
	dir=$(realpath "$dir")

	# rsync directory (trailing '/' needed)
	rsync -aPh --delete "$dir" "${MOUNT_DIR}/"
done
