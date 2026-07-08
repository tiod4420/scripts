#!/usr/bin/env bash
#
# List packages installed by different package managers

set -Eeuo pipefail

# Pacman packages
if command -v pacman &> /dev/null; then
	# Generate gnome.txt
	pacman -Qge | grep '^gnome[^ ]*' | cut -d' ' -f2 > gnome.txt

	# Generate texlive.txt
	pacman -Qge | grep '^texlive[^ ]*' | cut -d' ' -f2 > texlive.txt

	# Generate aur.txt
	pacman -Qqm > aur.txt

	# Generate pacman.txt
	pacman -Qqe | grep -xv -f gnome.txt -f texlive.txt -f aur.txt > pacman.txt

	# Generate all.txt
	pacman -Qq > all.txt
fi

# Cargo packages
if command -v cargo &> /dev/null; then
	cargo install --list > cargo.txt
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
if command -v apt-mark &> /dev/null; then
	apt-mark showmanual > termux.txt
fi
