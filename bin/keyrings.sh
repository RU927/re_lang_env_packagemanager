#!/bin/env bash

# if [ $# -eq 0 ]; then # Для работы скрипта необходим входной параметр.
# 	echo "Вызовите сценарий с параметрами: keyrings.sh sources_dir destination_dir "
# fi

# apt_dir=etc/apt
# sources_dir="$apt_dir"/sources.list.d
# keyrings_dir="$apt_dir"/keyrings

this_dir="$(dirname "$(realpath "$0")")"

sources_keyrings_dir=$this_dir/keyrings

# sources_keyrings_dir=$1
# destination_keyrings_dir=$2

# mkdir -p "$destination_keyrings_dir"
keys=$(command ls "$sources_keyrings_dir")

function update_bin_keyrings() {
	for k in $keys; do
		recv_keys=$(gpg -k --no-default-keyring --keyring "$sources_keyrings_dir/$k" \
      | grep -E "([0-9A-F]{40})" | tr -d " ")
    echo -E "$recv_keys"
		gpg --no-default-keyring \
			--keyring "$sources_keyrings_dir/$k" \
			--keyserver hkps://keyserver.ubuntu.com \
			--recv-keys "$recv_keys"
	done
}
update_bin_keyrings


# gpg --list-keys --with-colons | awk -F: '/^fpr:/ { print $10 }'
# gpg --list-keys --with-colons | awk -F: '/^pub:/ { print $5 }'
# gpg --no-default-keyring --keyring /etc/apt/keyrings/*.gpg --fingerprint
# gpg --no-default-keyring --keyring /etc/apt/keyrings/brave-browser-release.gpg --with-colons --fingerprint
# gpg --no-default-keyring --keyring /etc/apt/keyrings/brave-browser-release.gpg --with-colons --fingerprint | awk -F: '/^fpr:/ { print $10 }'
# gpg --no-default-keyring --keyring /etc/apt/keyrings/brave-browser-release.gpg --fingerprint | sed -n '/^\s/s/\s*//p'

function to_ascii_apt_keys() {
	for k in $keys; do
		gpg --export --armor --no-default-keyring --keyring "$sources_keyrings_dir/$k" -o "$destination_keyrings_dir/$k.key"
	done
}

# to_ascii_apt_keys
# echo -e "$1"
# echo -e "$2"