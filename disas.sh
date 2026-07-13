#!/usr/bin/env bash
#
# Objdump disassembly helper

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
	echo "usage: $0 [-h] [-o OBJDUMP] [-s SYMBOLS] binary"
	echo ""
	echo "Objdump disassembly helper"
	echo ""
	echo "positional arguments:"
	echo "  binary                       binary file to disassemble"
	echo ""
	echo "options:"
	echo "  -o, --objdump OBJDUMP        objdump command to use for disassembly"
	echo "                               (default: environment variable OBJDUMP, or 'objdump' if not set)"
	echo "  -s, --symbols SYMBOLS        list of symbols to disassemble"
	echo "                               (GNU objdump doesn't support multiple symbols)"
	echo "  -h, --help                   show this help message and exit"
}

# Get objdump flavour (GNU or LLVM)
flavor() {
	local version=$($1 --version 2> /dev/null | head -n 1)

	case "${version,,}" in
		*gnu*) echo "gnu" ;;
		*apple* | *llvm*) echo "llvm" ;;
	esac
}

OBJDUMP=${OBJDUMP:-}
SYMBOLS=

# Parse options
while [ "$#" -gt 0 ]; do
	case "$1" in
		-o | --objdump)
			[ -z "${2:-}" ] && error "option $1 requires an argument"
			[ -n "$OBJDUMP" ] && error "option $1 defined multiple times"
			OBJDUMP=$2
			shift 2
			;;
		-s | --symbols)
			[ -z "${2:-}" ] && error "option $1 requires an argument"
			[ -n "$SYMBOLS" ] && error "option $1 defined multiple times"
			SYMBOLS=$2
			shift 2
			;;
		-h | --help)
			usage
			exit 0
			;;
		--)
			shift
			break
			;;
		-*)
			error "invalid option -- ${1:-}"
			;;
		*)
			break
			;;
	esac
done

BINARY=${1:-}
OBJDUMP=${OBJDUMP:-objdump}

! [ -f "$BINARY" ] && error "invalid input file $BINARY"
! command -v "$OBJDUMP" &> /dev/null && error "$OBJDUMP is not an executable file"

# Set objdump options
ARGS=(--demangle)
[ -z "$SYMBOLS" ] && ARGS+=(--disassemble)

case "$(flavor "$OBJDUMP")" in
	gnu)
		ARGS+=(--disassembler-options=intel)
		[ -n "$SYMBOLS" ] && ARGS+=(--disassemble="$SYMBOLS")
		;;
	llvm)
		ARGS+=(--x86-asm-syntax=intel)
		[ -n "$SYMBOLS" ] && ARGS+=(--disassemble-symbols="$SYMBOLS")
		;;
esac

$OBJDUMP "${ARGS[@]}" "$BINARY"
