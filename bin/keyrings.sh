#!/bin/env bash

# if [ $# -eq 0 ]; then # Для работы скрипта необходим входной параметр.
# 	echo "Вызовите сценарий с параметрами: keyrings.sh sources_dir destination_dir "
# fi

# this_dir="$(dirname "$(realpath "$0")")"
# destination_dir=$this_dir/test
if [ $# -eq 1 ]; then
	sources_dir=$2
	destination_dir=$3
	keys=$(command ls "$sources_dir")
fi

function update_apt_keyrings() {
	# keys=$(command ls "$sources_dir")
	if [ -z "$keys" ]; then keys=$(command ls "$sources_dir"); fi
	for k in $keys; do
		name="${k%.*}"
		if [ -z "$recv_keys" ]; then
			recv_keys="$(gpg -k --no-default-keyring --keyring "$sources_dir/$name.gpg" |
				grep -E "([0-9A-F]{40})" | tr -d " ")"
		fi
		for r in $recv_keys; do
			gpg --no-default-keyring \
				--keyring "$sources_dir/$name.gpg" \
				--keyserver hkps://keyserver.ubuntu.com \
				--recv-keys "$r"
		done
		recv_keys=""
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
		mkdir -p "$destination_dir"
	fi

	for k in $keys; do
		name="${k%.*}"
		if [ ! -f "$destination_dir/$name.gpg" ]; then
			command cat "$sources_dir/$name.asc" | sudo gpg --dearmor \
				-o "$destination_dir/$name.gpg"
		# sudo gpg --dearmor --yes -o \
		# 	"$destination_dir/$name.gpg" < "$sources_dir/$name.asc"
		else
			tmp_dir=$TMP/apt-gpg-keys-$(date -I)
			mkdir -p "$tmp_dir"

			gpg --export --armor --no-default-keyring \
				--keyring "$destination_dir/$name.gpg" \
				-o "$tmp_dir/$name.asc"

			diff -q "$tmp_dir/$name.asc" "$sources_dir/$name.asc" >>/dev/null

			if [ $? -eq 1 ]; then
				echo "differ $name"
				# sudo mv "$destination_dir/$name.gpg" "$destination_dir/$name.old.gpg"
				# command cat "$sources_dir/$name.asc" | sudo gpg --dearmor \
				# -o "$destination_dir/$name.gpg"
			else
				echo "no action $name"
			fi
		fi
	done
}

function to_asc_apt_keys() {
	[ -d "$destination_dir" ] || mkdir -p "$destination_dir"
	# tmp_dir=$TMP/keys-$(date -I)
	for k in $keys; do
		name="${k%.*}"
		# echo -e "$name"
		if [ ! -f "$destination_dir/$name.asc" ]; then
			gpg --export --armor --no-default-keyring \
				--keyring "$sources_dir/$name.gpg" \
				-o "$destination_dir/$name.asc"
		else
			tmp_dir=$TMP/apt-keys-$(date -I)
			mkdir -p "$tmp_dir"

			gpg --export --armor --no-default-keyring \
				--keyring "$sources_dir/$name.gpg" \
				-o "$tmp_dir/$name.asc"

			diff -q "$tmp_dir/$name.asc" "$destination_dir/$name.asc" >>/dev/null

			if [ $? -eq 1 ]; then
				echo "differ $name"
			# mv "$destination_dir/$name.asc" "$destination_dir/$name.old.asc"
			# cp "$tmp_dir/$name.asc" "$destination_dir/"
			else
				echo "no action $name"
			fi
		fi
	done
}

for i in "$@"; do
	if [[ "$i" = --* ]]; then
		case $i in
		"--to-asc")
			if [ $# -eq 1 ]; then
				keyrings_dir=etc/apt/keyrings
				sources_dir="/$keyrings_dir"
				destination_dir="../$keyrings_dir"
				keys=$(command ls "$sources_dir")
			fi
			to_asc_apt_keys
			;;
		"--to-bin")
			if [ $# -eq 1 ]; then
				keyrings_dir=etc/apt/keyrings
				sources_dir="../$keyrings_dir"
				destination_dir="/$keyrings_dir"
				keys=$(command ls "$sources_dir")
			fi
			to_bin_apt_keys
			;;
		"--update-apt")
			if [ $# -eq 1 ]; then
				keyrings_dir=etc/apt/keyrings
				sources_dir="/$keyrings_dir"
			elif [ $# -ge 2 ]; then
				sources_dir=$2
				keys=$3
				recv_keys=$4 
			fi
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
