#!/usr/bin/env bash
#
# Backup list of directories to a gocryptfs vault

set -Eeuo pipefail

# Display error message, usage, and quit
error() {
	local msg=${1:-error}
	local ret=${2:-1}

	echo "$0: $msg" >&2

	exit $ret
}

# Cleanup function
cleanup() {
	local ret=$?

	echo "Unmounting vault at: $DESTINATION_DIR"

	# Disable exit on failure
	set +e

	# Unmount vault and wait a bit in case resource is busy
	if mountpoint -q "$DESTINATION_DIR"; then
		fusermount -u -- "$DESTINATION_DIR"
		sync
		sleep 1
	fi

	# Delete mount directory
	[ -d "$DESTINATION_DIR" ] && rmdir -- "$DESTINATION_DIR"

	exit $ret
}

# Backup directories
SOURCE_DIRS=(
	$HOME/Backups
	$HOME/Documents
)

VAULT_DIR=${1:-${VAULT_DIR:-}}

# Check if vault dir exists
! [ -d "$VAULT_DIR" ] && error "'$VAULT_DIR': No such file or directory"

# Create mount directory and setup cleanup
DESTINATION_DIR=$(mktemp --tmpdir --directory vault-mnt.XXXXXXXXXX)
echo "Mounting vault at: $DESTINATION_DIR"
trap cleanup EXIT

# Mount vault
if gocryptfs --info "$VAULT_DIR" > /dev/null; then
	gocryptfs -- "$VAULT_DIR" "$DESTINATION_DIR"
else
	error "'$VAULT_DIR': Not a gocryptfs vault"
fi

# Backup directories
for src in "${SOURCE_DIRS[@]}"; do
	# Check if source dir exists
	! [ -d "$src" ] && error "'$src': No such file or directory"

	# Resolve path and remove trailing '/'
	src=$(realpath -- "$src")

	# Rsync uses BSD convention
	# - rsync -r src dst: copy content of src into dst/src
	# - rsync -r src/ dst: copy content of src into dst
	rsync -aPh --delete -- "$src" "$DESTINATION_DIR"
done
