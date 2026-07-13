#!/usr/bin/env bash
#
# VirtualBox management helper

set -Eeuo pipefail

# Display error message, usage, and quit
error() {
	local msg=${1:-error}
	local ret=${2:-1}

	echo "$0: $msg" >&2
	usage >&2

	exit $ret
}

# Display usage
usage() {
	echo "usage: $0 [-h] {list,running,start,stop,poweroff} ..."
	echo ""
	echo "VirtualBox management helper"
	echo ""
	echo "commands:"
	echo "  list                         list all virtual machines"
	echo "  running                      list running virtual machines"
	echo "  start VM                     start a virtual machine (headless mode)"
	echo "  stop VM                      stop a virtual machine"
	echo "  poweroff VM                  power-off a virtual machine"
	echo ""
	echo "options:"
	echo "  -h, --help                   show this help message and exit"
}

CMD=
VM=

# Parse options
case "${1:-}" in
	list | running)
		CMD=$1
		shift
		;;
	start | stop | poweroff)
		[ -z "${2:-}" ] && error "command $1 requires an argument"
		CMD=$1
		VM=$2
		shift 2
		;;
	-h | --help)
		usage
		exit 0
		;;
	"")
		error "missing command"
		;;
	*)
		error "illegal command -- ${1:-}"
		;;
esac

# Run command
case "$CMD" in
	list) VBoxManage list vms ;;
	running) VBoxManage list runningvms ;;
	start) VBoxManage startvm --type headless "$VM" ;;
	stop) VBoxManage controlvm "$VM" acpipowerbutton ;;
	poweroff) VBoxManage controlvm "$VM" poweroff ;;
esac
