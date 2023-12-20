#!/usr/bin/env zsh

set -eu

function bump_maxfiles_limit {
	local target_file=/Library/LaunchDaemons/dev.fsouza.limit-maxfiles.plist

	if ! [ -f ${target_file} ]; then
		set -x
		: "Installing LaunchDaemon to bump maxfiles limit (enter sudo password if requested)"
		local tmp_file=$(mktemp)
		cat >${tmp_file} <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
        "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>dev.fsouza.limit-maxfiles</string>
    <key>ProgramArguments</key>
    <array>
      <string>launchctl</string>
      <string>limit</string>
      <string>maxfiles</string>
      <string>49152</string>
      <string>49152</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>ServiceIPC</key>
    <false/>
  </dict>
</plist>
EOF
		sudo cp ${tmp_file} ${target_file}
		sudo launchctl load -w ${target_file}
		set +x
	fi
}

function _find_bin {
	local bin_name=${1}
 	local candidates=(/opt/homebrew/bin/${bin_name} /usr/local/bin/${bin_name})
	for path in ${candidates}; do
		if [ -x ${path} ]; then
			echo ${path}
			return 0
		fi
	done
}

function find_brew {
	_find_bin brew
}

function find_op {
	_find_bin op
}

function install_brew {
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
}

function setup_brew {
	local brew=$(find_brew)
	if [ -z "${brew}" ]; then
		install_brew
		brew=$(find_brew)
	fi
	eval "$(${brew} shellenv)"
	export HOMEBREW_NO_AUTO_UPDATE=1
	export HOMEBREW_NO_EMOJI=1
	export HOMEBREW_NO_GITHUB_API=1
	brew update
	brew install gh zsh gnupg

	echo
	echo
	echo "==================================="
	echo "installing and configuring 1password-cli (may ask for sudo password)"

	brew install --cask 1password-cli
	$(find_op) signin -f
}

function gh_ssh_setup {
	if ! gh auth status &>/dev/null; then
		echo "we're now going to login to GitHub, using gh. Make sure to create or upload the SSH key in the next step."
		gh auth login -h github.com -p ssh -s admin:gpg_key -s admin:public_key --web
		ssh-keyscan github.com >>${HOME}/.ssh/known_hosts
	fi
}

function add_gpg_key_to_gh {
	local keyemail=${1}
	gpg -a --export ${keyemail} | gh gpg-key add - &>/dev/null
}

function setup_gpg {
	local email="108725+fsouza@users.noreply.github.com"
	if ! gpg --list-keys ${email} &>/dev/null; then
		gpg --batch --passphrase '' --quick-gen-key "francisco souza <${email}>" rsa4096
		add_gpg_key_to_gh ${email}
	fi
}

function setup_dotfiles {
	local target_dir=${1}
	if [ ! -d ${target_dir} ]; then
		mkdir -p $(dirname ${target_dir})
		git clone git@github.com:fsouza/dotfiles.git ${target_dir}

		${target_dir}/bootstrap/setup
		env FSOUZA_DOTFILES_DIR=${target_dir} ${HOMEBREW_PREFIX}/bin/zsh -l <<EOF
source ${FSOUZA_DOTFILES_DIR}/zsh/.zshrc

set -e
update_go_tip
EOF
	fi
}

function setup_rclone {
	sudo mkdir -p /usr/local/bin /usr/local/share
	sudo chown ${USER}:wheel /usr/local/bin /usr/local/share
	if ! [ -f ${HOME}/.config/rclone/rclone.conf ]; then
		mkdir -p ${HOME}/.config/rclone
		local conf_file=$(mktemp)
		chmod 600 ${conf_file}
		op document get rclone-conf --output ${conf_file}
		mv ${conf_file} ${HOME}/.config/rclone/rclone.conf
	fi
}

function install_node {
	env FSOUZA_DOTFILES_DIR=${1} ${HOMEBREW_PREFIX}/bin/zsh -l <<'EOF'
source ${FSOUZA_DOTFILES_DIR}/zsh/.zshrc

set -e
export PATH=${HOME}/.dotfiles/bin:${HOME}/.cargo/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:${PATH}
fnm install v20
fnm default v20
EOF
}

function setup_nvim {
	env FSOUZA_DOTFILES_DIR=${1} ${HOMEBREW_PREFIX}/bin/zsh -l <<'EOF'
source ${FSOUZA_DOTFILES_DIR}/zsh/.zshrc

set -e
update_neovim

bump_dotfiles
EOF
}

function main {
	local dotfiles_dir=${HOME}/Projects/os/p/dotfiles

	bump_maxfiles_limit
	setup_brew
	gh_ssh_setup
	setup_gpg

	setup_rclone
	setup_dotfiles ${dotfiles_dir}
	install_node ${dotfiles_dir}
	setup_nvim ${dotfiles_dir}
}

main
