#!/usr/bin/env bash

# TODO: dircolors --print-ls-colors

[ -f "$1" ] && eval $(dircolors "$1")

ls_colors=(${LS_COLORS//:/ })

reset="\e[0m"

for i in ${!ls_colors[@]}; do
	ext=${ls_colors[${i}]%%=*}
	color=${ls_colors[${i}]##*=}
	pad=$((12 - ${#ext}))

	fg_color="\e[${color}m"

	if [ 0 -ne ${i} ]; then
		[ 0 -eq $((${i} % 8)) ] && printf "\n" || printf "\t"
	fi

	printf "${fg_color}%s${reset}" "${ext}"
	printf "%-${pad}s" ""
done

[ 0 -ne ${#ls_colors[@]} ] && printf "\n"

exit 0
