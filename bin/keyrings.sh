#!/bin/env bash

# if [ $# -eq 0 ]; then # Для работы скрипта необходим входной параметр.
# 	echo "Вызовите сценарий с параметрами: keyrings.sh sources_dir destination_dir "
# fi

# this_dir="$(dirname "$(realpath "$0")")"
# destination_dir=$this_dir/test

sources_dir=$2
destination_dir=$3

keys=$(command ls "$sources_dir")

function update_apt_keyrings() {
	for k in $keys; do
		name="${k%.*}"
		recv_keys=$(gpg -k --no-default-keyring --keyring "$sources_dir/$name.gpg" |
			grep -E "([0-9A-F]{40})" | tr -d " ")
		gpg --no-default-keyring \
			--keyring "$sources_dir/$name.gpg" \
			--keyserver hkps://keyserver.ubuntu.com \
			--recv-keys "$recv_keys"
	done
}

function update_gpg_keyrings() {
	recv_keys=$(gpg -k --with-colons | awk -F: '/^fpr:/ { print $10 }')
	for r in $recv_keys; do
		gpg --keyserver keyserver.ubuntu.com --recv-keys "$r"
	done
}

function to_bin_apt_keys() {

	if [ -d "$destination_dir" ]; then
		sudo mv "$destination_dir" "$destination_dir.old"
		sudo mkdir -p "$destination_dir"
	else
		sudo mkdir -p "$destination_dir"
	fi

	for k in $keys; do
		name="${k%.*}"
		command cat "$sources_dir/$name.asc" | sudo gpg --dearmor \
			-o "$destination_dir/$name.gpg"
		# sudo gpg --dearmor --yes -o \
		# 	"$destination_dir/$name.gpg" < "$sources_dir/$name.asc"
	done
}

function to_asc_apt_keys() {
	[ -d "$destination_dir" ] || mkdir -p "$destination_dir"
	# tmp_dir=$TMP
	for k in $keys; do
		name="${k%.*}"
		if [ ! -f "$destination_dir/$name.asc" ]; then
			gpg --export --armor --no-default-keyring \
				--keyring "$sources_dir/$name.gpg" \
				-o "$destination_dir/$name.asc"
			# else
			# 	gpg --export --armor --no-default-keyring \
			# 		--keyring "$sources_dir/$name.gpg" \
			# 		-o "$tmp_dir/$name.asc"
			# if ! "$tmp_dir/$name.asc" -eq "$destination_dir/$name.asc" ;
			#   diff "$tmp_dir/$name.asc" "$destination_dir/$name.asc"
			# fi

		fi
	done
}

# if [ $# -eq 1 ]; then
# 	sources_dir="/etc/apt/keyrings"
# 	destination_dir="../etc/apt/keyrings"
# 	keys=$(command ls "$sources_dir")
# fi

for i in "$@"; do
	if [[ "$i" = --* ]]; then
		case $i in
		"--to-asc")
			to_asc_apt_keys
			;;
		"--to-bin")
			to_bin_apt_keys
			;;
		"--update-apt")
			update_apt_keyrings
			;;
		"--update-gpg")
			update_gpg_keyrings
			;;
		esac
	fi
done

# echo -e "$1"
# echo -e "$2"

# gpg -k --no-default-keyring --keyring ./*.gpg

# gpg --homedir /tmp --no-default-keyring --keyring "$destination_keyrings_dir/$name" \
# gpg --list-keys --with-colons | awk -F: '/^fpr:/ { print $10 }'
# gpg --no-default-keyring --keyring /etc/apt/keyrings/brave-browser-release.gpg --with-colons --fingerprint | awk -F: '/^fpr:/ { print $10 }'
# gpg --no-default-keyring --keyring /etc/apt/keyrings/brave-browser-release.gpg --fingerprint | sed -n '/^\s/s/\s*//p'
