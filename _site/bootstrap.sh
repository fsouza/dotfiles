#!/usr/bin/env zsh

set -eu

function setup_rosetta {
	if [[ $(uname -m) == "arm64" ]]; then
		set -x
		: "Installing rosetta (enter sudo password if requested)"
		sudo softwareupdate --install-rosetta --agree-to-license
		set +x
	fi
}

function bump_maxfiles_limit {
	set -x
	: "Installing LaunchDaemon to bump maxfiles limit (enter sudo password if requested)"
	tmp_file=$(mktemp -d)
	cat >"${tmp_file}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
        "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>limit-maxfiles</string>
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
	sudo cp "${tmp_file}" /Library/LaunchDaemon
	sudo launchctl load -w /Library/LaunchDaemons/dev.fsouza.limit-maxfiles.plist
	set +x
}

function find_brew {
	candidates=(/opt/homebrew/bin/brew /usr/local/bin/brew)
	for path in ${candidates}; do
		if [ -x "${path}" ]; then
			echo "${path}"
			return 0
		fi
	done
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
	eval "$("${brew}" shellenv)"
	HOMEBREW_NO_AUTO_UPDATE=1
	HOMEBREW_NO_EMOJI=1
	HOMEBREW_NO_GITHUB_API=1
	export HOMEBREW_NO_AUTO_UPDATE HOMEBREW_NO_EMOJI HOMEBREW_NO_GITHUB_API
	brew update
	brew install gh zsh
	brew install --cask 1password-cli
}

function gh_ssh_setup {
	echo "we're now going to login to GitHub, using gh. Make sure to create or upload the SSH key in the next step."
	echo "Press any key to continue..."
	read
	gh auth login -h github.com -p ssh -s admin:gpg_key -s admin:public_key --web
	ssh-keyscan github.com >>"$HOME"/.ssh/known_hosts
}

function add_gpg_key_to_gh {
	local keyemail=${1}
	local keyname=gpg-$(hostname -s)-${RANDOM}
	gh api /user/gpg_keys -X POST -F "name=${keyname}" -F "armored_public_key=$(gpg -a --export "${keyemail}")"
}

function setup_gpg {
	local email="108725+fsouza@users.noreply.github.com"
	if ! gpg --list-keys "${email}" &>/dev/null; then
		gpg --batch --passphrase '' --quick-gen-key "francisco souza <${email}>" rsa4096
		add_gpg_key_to_gh "${email}"
	fi
}

function setup_dotfiles {
	if [ ! -d "$HOME/.dotfiles" ]; then
		git clone git@github.com:fsouza/dotfiles.git "$HOME"/.dotfiles

		"$HOME"/.dotfiles/bootstrap/setup
		"${HOMEBREW_PREFIX}"/bin/zsh -l <<'EOF'
source "${HOME}"/.zshrc

set -e
update_go_tip
EOF
	fi
}

function setup_rclone {
	sudo mkdir -p /usr/local/bin /usr/local/share
	sudo chown ${USER}:wheel /usr/local/bin /usr/local/share
	mkdir -p "$HOME"/.config/rclone
	op document get rclone-conf --output "$HOME"/.config/rclone/rclone.conf
	chmod 600 "$HOME"/.config/rclone/rclone.conf
}

function install_node {
	"${HOMEBREW_PREFIX}"/bin/zsh -l <<'EOF'
source $HOME/.zshrc

set -e
export PATH=${HOME}/.dotfiles/bin:${HOME}/.cargo/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:$PATH
fnm install v18
fnm default v18
EOF
}

function setup_nvim {
	"${HOMEBREW_PREFIX}"/bin/zsh -l <<'EOF'
source $HOME/.zshrc

set -e
update_neovim

# source again after installing neovim.
set +e
source $HOME/.zshrc
set -e

bump_dotfiles
EOF
}

function main {
	setup_rosetta
	bump_maxfiles_limit
	setup_brew
	gh_ssh_setup
	setup_gpg

	setup_rclone
	setup_dotfiles
	install_node
	setup_nvim
}

main