#!/usr/bin/env bash
#
# Disassemble function

local OPTARG
local OPTIND
local opts
local objdump
local version
local binary
local arch
local symbols
local arch_args
local args

# Set objdump binary
objdump=objdump
[ -n "$OBJDUMP" ] && objdump=$OBJDUMP

# Parse arguments
while getopts ":a:s:" opts; do
	case "$opts" in
		a) arch=$OPTARG;;
		s) symbols=$OPTARG;;
		\?) (1>&2 echo "${FUNCNAME}: invalid parameter: -${OPTARG}") && return 1;;
	esac
done

shift $((OPTIND - 1))
binary="$1"

if [ -z "$binary" ] || [ -z "$objdump" ]; then
	echo "usage: ${FUNCNAME} [-a ARCH] [-s SYMBOLS] BINARY" >&2
	return 1
fi

# Get objdump flavour (GNU or LLVM)
if $objdump --version | grep -qi gnu; then
	version=gnu
else
	version=llvm
fi

# Get target architecture
if [ -z "$arch" ]; then
	if file "$binary" | grep -qi x86; then
		arch=x86
	fi
fi

# Set parameters
case "$version" in
	gnu) args=${symbols:+--disassemble="${symbols}"};;
	llvm) args=${symbols:+--disassemble-symbols="${symbols}"};;
esac

case "${version}_${arch:-none}" in
	gnu_x86) arch_args=--disassembler-options=intel;;
	llvm_x86) arch_args=--x86-asm-syntax=intel;;
esac

$objdump --demangle ${arch_args} ${args:---disassemble} $binary
