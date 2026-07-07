#!/usr/bin/env bash
#
# Misc, used to setup termcap

# TODO: check how to extract capabilities
# TODO: check how to install capabilities
# TODO: Check if capabilities is here

show_terminfo() {
	infocmp -1 | tr -d '\0\t,' | cut -d '=' -f 1 | grep -v "$TERM" | sort | column -c 80
}

setup_terminfo() {
	# Deploy missing terminfo files
	deploy_terminfo alacritty terminfo/alacritty.info
	deploy_terminfo alacritty-direct terminfo/alacritty.info
	deploy_terminfo tmux-256color terminfo/terminfo.src
}


deploy_terminfo() {
	local RES
	local termname
	local file
	local location

	[ -n "$1" ] && termname="$1" || return 1
	[ -n "$2" ] && file="$2" || return 1

	location=$(find "${HOME}/.terminfo" -name "$termname" 2> /dev/null)

	if [ -n "$location" ]; then
		# Terminfo is installed by the user
		file_status "$termname" "SKIP"
	elif infocmp "$termname" &> /dev/null; then
		# Terminfo is installed by the system
		file_status "$termname" "SKIP"
	else
		# Terminfo is not installed
		tic -xe "$termname" "$file"
		RES=$?; [ 0 -ne $RES ] && return 1

		file_status "$termname" "DEPLOYED"
	fi

	return 0
}
