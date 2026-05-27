#!/usr/bin/env bash

safe=${HOME}/.local/share/Cryptomator/mnt/Safe/

if [ ! -d "$safe" ]; then
	echo "$safe: Cryptomator safe not mounted" >&2
	exit 1
fi

# Backup and delete extra files
rsync -aPh --delete ${HOME}/Backup "$safe"
rsync -aPh --delete ${HOME}/Documents "$safe"
