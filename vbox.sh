#!/usr/bin/env bash
#
# VirtualBox helper

local cmd="$1"
local vm="$2"

case "$cmd" in
	list)
		# List all virtual machines
		VBoxManage list vms
		;;
	running)
		# List running virtual machines
		VBoxManage list runningvms
		;;
	start)
		# Start a VM (headless mode)
		[ -z "$vm" ] && echo "usage: ${FUNCNAME} ${cmd} VM" >&2 && return 1
		VBoxManage startvm --type headless "$vm"
		;;
	stop)
		# Stop a VM
		[ -z "$vm" ] && echo "usage: ${FUNCNAME} ${cmd} VM" >&2 && return 1
		VBoxManage controlvm "$vm" acpipowerbutton
		;;
	poweroff)
		# Force stop a VM
		[ -z "$vm" ] && echo "usage: ${FUNCNAME} ${cmd} VM" >&2 && return 1
		VBoxManage controlvm "$vm" poweroff
		;;
	*)
		echo "${FUNCNAME}: unknown command '${cmd}'" >&2
		echo "usage: ${FUNCNAME} COMMAND [VM]" >&2
		return 1
		;;
esac
