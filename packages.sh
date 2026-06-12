#!/usr/bin/env bash

set -Eeuo pipefail

# Pacman packages
if command -v pacman &> /dev/null; then
	# Generate gnome.txt
	pacman -Qge | grep '^gnome ' | cut -d' ' -f2 > gnome.txt

	# Generate gnome-extra.txt
	pacman -Qge | grep '^gnome-extra ' | cut -d' ' -f2 > gnome-extra.txt

	# Generate texlive.txt
	pacman -Qge | grep '^texlive' | cut -d' ' -f2 > texlive.txt

	# Generate aur.txt
	pacman -Qqm > aur.txt

	# Generate pacman.txt
	pacman -Qqe | grep -v -x -f gnome.txt -f gnome-extra.txt -f texlive.txt -f aur.txt > pacman.txt

	# Generate all.txt
	pacman -Qq > all.txt
fi

# Homebrew packages
if command -v brew &> /dev/null; then
	brew list --installed-on-request > homebrew.txt
fi

# MacPort packages
if command -v port &> /dev/null; then
	port -q echo requested > macports.txt
fi

# Termux packages
if command -v pkg &> /dev/null; then
	pkg list-all --manual-installed | cut -d'/' -f1 > termux.txt
fi

# Cargo packages
if command -v cargo &> /dev/null; then
	cargo install --list > cargo.txt
fi
