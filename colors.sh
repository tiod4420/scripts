#!/usr/bin/env bash
#
# Display different colors

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
	echo "usage: $0 [-h] {16color,256color,truecolor,base16,dircolors,ls,vim} ..."
	echo ""
	echo "Display different colors"
	echo ""
	echo "commands:"
	echo "  16color                      display terminal 16 colors (4-bit)"
	echo "  256color                     display terminal 256 colors (8-bit)"
	echo "  truecolor [LENGTH]           display terminal TrueColor (24-bit)"
	echo "                               LENGTH control the length of printed string (default: 64)"
	echo "  base16                       display Base16 colors"
	echo "  dircolors [FILE]             display dircolors database colors"
	echo "                               if FILE is specified, it is used as color database"
	echo "  ls [FILE]                    display ls colors such as defined in LS_COLORS"
	echo "                               if FILE is specified, it is used by dircolors to evaluate LS_COLORS"
	echo "                               if LS_COLORS is not set, default dircolors output is used"
	echo "  vim                          open vim and display colors from syntax/colortest.vim"
	echo ""
	echo "options:"
	echo "  -h, --help                   show this help message and exit"
}

# Print color with text, and reset
print_color() {
	local color="\e[${1:-0}m"
	local pad=${2:-0}
	local text=${3:-$color}
	local reset="\e[0m"

	printf "${color}%s${reset}" "$text"

	if [ "$pad" -gt 0 ]; then
		printf "%-$((pad - ${#text}))s" ""
	fi
}

# 4-bit colors
show_16color() {
	local colors=($(seq 0 7) 9 $(seq 60 67))
	local attrs=(0 1 2 4 5 7)

	for i in "${colors[@]}"; do
		for j in "${colors[@]}"; do
			for attr in "${attrs[@]}"; do
				local bg_color=$((i + 40))
				local fg_color=$((j + 30))

				print_color "$attr;$bg_color;$fg_color"
				echo ""
			done
		done
	done | column -x
}

# 8-bit colors
show_256color() {
	local attrs=(38 48)

	for attr in "${attrs[@]}"; do
		for i in $(seq 0 31); do
			for j in $(seq 0 7); do
				local color=$((i * 8 + j))

				print_color "$attr;5;$color" 12
				echo ""
			done
		done
	done | column -x
}

# 24-bit (TrueColor) colors
show_truecolor() {
	local len=${1:-64}
	local attrs=(38 48)

	if [ "$len" -lt 2 ]; then
		error "truecolor length should be at least 2"
	fi

	for attr in "${attrs[@]}"; do
		for i in $(seq 0 $((len - 1))); do
			local idx=$((i * 255 / (len - 1)))

			local r=$((255 - idx))
			local b=$((idx))
			local g=$((idx < 128 ? 2 * b : 2 * r))

			print_color "$attr;2;${r};${g};${b}" 0 "~"
		done

		echo ""
	done
}

# Base16 colors
show_base16() {
	# Not a hashmap because we care about order
	local colors=(
		base00:Black
		base08:Red
		base0B:Green
		base0A:Yellow
		base0D:Blue
		base0E:Magenta
		base0C:Cyan
		base05:White
		base03:Bright_Black
		base08:Bright_Red
		base0B:Bright_Green
		base0A:Bright_Yellow
		base0D:Bright_Blue
		base0E:Bright_Magenta
		base0C:Bright_Cyan
		base07:Bright_White
		base09:
		base0F:
		base01:
		base02:
		base04:
		base06:
	)

	for i in "${!colors[@]}"; do
		local base16_name=${colors[$i]%%:*}
		local ansi_name=${colors[$i]##*:}

		printf "color%02d " $i
		print_color "38;5;$i" 32 "${base16_name} ${ansi_name:-}"
		printf "|"
		print_color "48;5;$i" 32 "$(printf "%32s" "")"
		printf "|\n"
	done
}

# dircolors colors
show_dircolors() {
	local file=${1:-}
	dircolors --print-ls-colors ${file:+"$file"}
}

# LS_COLORS colors
show_ls() {
	local file=${1:-}

	# Get LS_COLORS
	if [ -n "$file" ] || [ -z "$LS_COLORS" ]; then
		eval $(dircolors ${file:+"$file"})
	fi

	local ls_colors=(${LS_COLORS//:/ })

	# Show colors
	for entry in "${ls_colors[@]}"; do
		local color=${entry##*=}
		local name=${entry%%=*}

		print_color "$color" 16 "$name"
		echo ""
	done | column -x
}

# Vim colors
show_vim() {
	vim -c ':runtime syntax/colortest.vim'
}

CMD=
ARG=

# Parse options
case "${1:-}" in
	16color|256color|base16|vim)
		CMD=$1
		shift
		;;
	dircolors|ls|truecolor)
		CMD=$1
		ARG=${2:-}
		shift ${ARG:+2}
		;;
	-h|--help)
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
	16color) show_16color ;;
	256color) show_256color ;;
	truecolor) show_truecolor "${ARG:-}" ;;
	base16) show_base16 ;;
	dircolors) show_dircolors "${ARG:-}" ;;
	ls) show_ls"${ARG:-}" ;;
	vim) show_vim ;;
esac
