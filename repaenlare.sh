#!/usr/bin/env bash

RC='\e[0m'
RED='\e[31m'
YELLOW='\e[33m'
GREEN='\e[32m'
WHITE='[37;1m'

RV='\u001b[7m'

this_dir="$(dirname "$(realpath "$0")")"
dot_config=$this_dir/config
dot_home=$this_dir/home
config_dir=$HOME/.config
src_dir=$HOME/src

linkExists() {
	[[ -e "$1" ]] && [[ -L "$1" ]]
}
configExists() {
	[[ -e "$1" ]]
}

command_exists() {
	command -v "$1" >/dev/null 2>&1
}

check_prerequisites() {
	if [ "${BASH_VERSION:-}" = "" ]; then
		abort "Bash is required to interpret this script."
	fi
	# [ "${BASH_VERSINFO:-0}" -ge 4 ] || install_bash=1

	if [[ $EUID -eq 0 ]]; then
		abort "Script must not be run as root user"
	fi

	architecture=$(uname -m)
	if [[ $architecture =~ "arm" || $architecture =~ "aarch64" ]]; then
		abort "Only amd64/x86_64 is supported"
	fi
}
check_prerequisites

checkEnv() {
	## Check Package Handeler
	PACKAGEMANAGER='apt dnf'
	for pgm in ${PACKAGEMANAGER}; do
		if command_exists "${pgm}"; then
			PACKAGER=${pgm}
			echo -e "${RV}Using ${pgm}"
		fi
	done

	if [ -z "${PACKAGER}" ]; then
		echo -e "${RED}Can't find a supported package manager"
		exit 1
	fi

	## Check if the current directory is writable.
	PATHs="$this_dir $config_dir"
	for path in $PATHs; do
		if [[ ! -w ${path} ]]; then
			echo -e "${RED}Can't write to ${path}${RC}"
			exit 1
		fi
	done
}
checkEnv

function install_packages {
	DEPENDENCIES='curl wget python3 pipx aptitude nala libxml2-dev luakit apt-transport-https'

	# sudo apt install --upgrade ca-certificates
	# sudo apt-key adv --refresh-keys --keyserver keyserver.ubuntu.com

	sudo "${PACKAGER}" install ${DEPENDENCIES}
}

function back_sym {
	# перед создание линков делает бекапы только тех пользовательских конфикураций,
	# файлы которых есть в ./config ./home
	echo -e "\u001b${YELLOW} Backing up existing files... ${RC}"
	for config in $(command ls "${dot_config}"); do
		if linkExists "${config_dir}/${config}"; then
			echo -e "${YELLOW}Removing old link ${config_dir}/${config} ${RC}"
			if ! rm -rf "${config_dir}/${config}"; then
				echo -e "${RED}Can't remove the old link!${RC}"
				exit 1
			fi
			# echo -e "${WHITE} Remove backups with 'rm -ir ~/.*.old && rm -ir ~/.config/*.old' ${RC}"
    elif configExists "${config_dir}/${config}"; then
      echo -e "${YELLOW}Moving old config ${config_dir}/${config} -> ${config_dir}/$config.old($(date -u +%d-%B-%H:%M:%S)) ${RC}"
      if ! mv "${config_dir}/${config}" "${config_dir}/${config}.old($(date -u +%d-%B-%H:%M:%S))"; then
				echo -e "${RED}Can't backup the old config!${RC}"
				exit 1
			fi
		fi
		echo -e "${GREEN}Copy ${dot_config}/${config} to ${config_dir}/${config}${RC}"
		if ! cp -a "${dot_config}/${config}" "${config_dir}/${config}"; then
			echo echo -e "${RED}Can't copy the config!${RC}"
			exit 1
		fi
	done

	for config in $(command ls "${dot_home}"); do
		if linkExists "$HOME/.${config}"; then
			echo -e "${YELLOW}Removing old link ${HOME}/.${config}"
			if ! rm -f "${HOME}/.${config}"; then
				echo -e "${RED}Can't move the old config!${RC}"
				exit 1
			fi
    elif configExists "${HOME}/.${config}"; then
      echo -e "${YELLOW}Moving old config ${HOME}/.${config} -> ${HOME}/.$config.old($(date -u +%d-%B-%H:%M:%S)) ${RC}"
      if ! mv "${HOME}/.${config}" "${HOME}/.${config}.old($(date -u +%d-%B-%H:%M:%S))"; then
				echo -e "${RED}Can't backup the old config!${RC}"
				exit 1
			fi
			# echo -e "${WHITE} Remove backups with 'rm -ir ~/.*.old && rm -ir ~/.config/*.old' ${RC}"
		fi
		echo -e "${GREEN}Copy ${dot_home}/${config} to ${HOME}/.${config}${RC}"
		if ! cp -a "${dot_home}/${config}" "${HOME}/.${config}"; then
			echo echo -e "${RED}Can't copy the config!${RC}"
			exit 1
		fi
	done
}

function apt_key() {

	apt_dir=etc/apt
	# sources_dir="/$apt_dir"/sources.list.d
	# dest_dir="$this_dir/test"
  
	# source_dir="$apt_dir"
	# dest_dir="/$apt_dir"

	# sudo rm -rf "/$apt_dir/keyrings"
  sudo mv "/$apt_dir/sources.list" "/$apt_dir/sources.list.old"

  sudo ./bin/keyrings.sh --to-bin
	sudo ln -svnf "$this_dir/$apt_dir/sources.list.d" "/$apt_dir"
}

lua_version="5.4.6"
luarocks_version="3.9.2"

src_lua_dir="${src_dir}/lua"
src_luarocks_dir="${src_dir}/luarocks"

# Lua
function install_lua {
	if ! command_exists lua; then
		echo -e "${RV} Installing Lua ${RC}"
		mkdir -p "$src_lua_dir"
		cd "$src_dir" || return
		curl -R -O http://www.lua.org/ftp/lua-"$lua_version".tar.gz
		tar -zxf lua-"$lua_version".tar.gz
		cd lua || return
		#make linux test
		sudo make install
		rm -rf lua-"$lua_version".tar.gz
	else
		echo -e "${RV} Lua is installed ${RC}"
	fi
}

# Luarocks
function install_luarocks {
	if command_exists lua; then
		if ! command_exists luarocks; then
			echo -e "${RV} Installing Luarocks... ${RC}"
			mkdir -p "$src_luarocks_dir"
			cd "$src_luarocks_dir" || return
			wget https://luarocks.org/releases/luarocks-"$luarocks_version".tar.gz
			tar -zxpf luarocks-"$luarocks_version".tar.gz
			rm -rf luarocks-"$luarocks_version".tar.gz
			cd luarocks-"$luarocks_version" || return
			./configure --with-lua-include=/usr/include/lua5.4/
			make
			sudo make install
		else
			echo -e "${RV} Luarocks is installed${RC}"
		fi
	else
		echo -e "${RED}Lua is not installed!${RC}"
		install_lua
		install_luarocks
	fi
}

function install_r {
	echo -e "${RV} Installing R... ${RC}"
	#R
	# wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
	# gpg --show-keys /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
	# sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu jammy-cran40/"
	sudo apt-get update
	sudo apt-get install r-base
	sudo apt-get install r-base-dev libxml2-dev
	# sudo add-apt-repository ppa:c2d4u.team/c2d4u4.0+
	# sudo apt install --no-install-recommends r-cran-tidyverse
	# deb https://<my.favorite.ubuntu.mirror>/ focal-backports main restricted universe
	R --version
}

function install_conda {
	echo -e "${RV} Installing Conda... ${RC}"

	wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -P "$src_dir"
	bash "$src_dir"/Miniconda3-latest-Linux-x86_64.sh
}

function install_cargo {
	## Check for dependencies.
	# DEPEND='libfontconfig1-dev libxcb-shape0-dev libxcb-xfixes0-dev libxkbcommon-dev'
	# echo -e "${RV}${YELLOW} Installing dependencies${RC}"
	# sudo "${PACKAGER}" install -yq "${DEPEND}"
	# Rust,Cargo
	if ! command_exists cargo; then
		echo -e "${RV} Installing Cargo ${RC}"
		CARGO_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/cargo"
		RUSTUP_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/rustup"
		mkdir -p "$CARGO_HOME" "$RUSTUP_HOME"
		curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
	else
		echo -e "${RV} Rust is installed${RC}"
	fi
}

function install_nodejs {

	echo -e "\u001b[7m Installing NodeJS... \u001b[0m"
	# nodejs
	# node version manager
	NVM_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvm"
	mkdir -p "$NVM_DIR"
	if ! command_exists nvm; then
		git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
		cd "$NVM_DIR" || exit
		git checkout "$(git rev-list --tags --max-count=1)"
		# git checkout "$(git describe --abbrev=0 --tags --match "v[0-9]*" "$(git rev-list --tags --max-count=1)")"
	else
		cd "$NVM_DIR" || exit
		git fetch --tags origin
		git checkout "$(git rev-list --tags --max-count=1)"
		# git checkout "$(git describe --abbrev=0 --tags --match "v[0-9]*" "$(git rev-list --tags --max-count=1)")"
	fi

	# PROFILE=/dev/null bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash'

	if ! command_exists fnm; then
		if command_exists cargo; then
			cargo install fnm
		else
			install_cargo
			cargo install fnm
		fi
	fi

	# sudo apt remove nodejs
	# sudo apt autoremove
	# curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
	# sudo apt install -y nodejs
	# node -v
	# npm -v
}

function install_debget {
	echo -e "${RV} Installing deb-get ${RC}"
	#deb-get
	curl -sL https://raw.githubusercontent.com/wimpysworld/deb-get/main/deb-get | sudo -E bash -s install deb-get
	# deb-get install google-chrome-stable zoom exodus discord flameshot balena-etcher-electron whatsapp-for-linux
}

install_homebrew() {
	"$this_dir/bin/install_homebrew.sh"
}
function all {
	echo -e "\u001b[7m Setting up Dotfiles... \u001b[0m"
	install_packages
	back_sym
	apt-key
	install_lua
	install_luarocks
	install_r
	install_conda
	install_cargo
	install_nodejs
	install_homebrew
	install_debget
	echo -e "\u001b[7m Done! \u001b[0m"
}

if [ "$1" = "--backsym" ] || [ "$1" = "-b" ]; then
	back_sym
	exit 0
fi

if [ "$1" = "--all" ] || [ "$1" = "-a" ]; then
	all
	exit 0
fi

# Menu TUI
echo -e "\u001b[32;1m Setting up Dotfiles...\u001b[0m"

echo -e " \u001b[37;1m\u001b[4mSelect an option:\u001b[0m"
echo -e "  \u001b[34;1m (a) ALL \u001b[0m"
echo -e "  \u001b[34;1m (k) apt key \u001b[0m"
echo -e "  \u001b[34;1m (p) install packages \u001b[0m"
echo -e "  \u001b[34;1m (s) backup and symlink \u001b[0m"
echo -e "  \u001b[34;1m (l) install lua \u001b[0m"
echo -e "  \u001b[34;1m (r) install luarocks (5,6,13) \u001b[0m"
echo -e "  \u001b[34;1m (R) install R \u001b[0m"
echo -e "  \u001b[34;1m (c) install conda \u001b[0m"
echo -e "  \u001b[34;1m (C) install cargo \u001b[0m"
echo -e "  \u001b[34;1m (n) install NodeJS \u001b[0m"
echo -e "  \u001b[34;1m (b) install brew \u001b[0m"
echo -e "  \u001b[34;1m (d) install deb-get \u001b[0m"

echo -e "  \u001b[31;1m (*) Anything else to exit \u001b[0m"

echo -en "\u001b[32;1m ==> \u001b[0m"

read -r option

case $option in

"a")
	all
	;;

"k")
	apt_key
	;;

"p")
	install_packages
	;;

"s")
	back_sym
	;;

"l")
	install_lua
	;;

"r")
	install_luarocks
	;;

"R")
	install_r
	;;

"c")
	install_conda
	;;

"C")
	install_cargo
	;;

"n")
	install_nodejs
	;;

"b")
	install_homebrew
	;;

"d")
	install_debget
	;;

*)
	echo -e "\u001b[31;1m Invalid option entered, Bye! \u001b[0m"
	exit 0
	;;
esac

exit 0
