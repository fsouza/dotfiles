basedir=$(dirname "$(realpath "${(%):-%N}")")
source "${basedir}"/extra/init-functions

export MANPATH=/usr/share/man:/usr/local/share/man:"${basedir}"/extra/z
export GOBIN=$HOME/bin GOPATH=$HOME/.go GIMME_SILENT_ENV=1 GIMME_TYPE=binary
export EDITOR=vim PAGER=less MANPAGER=less
export RIPGREP_CONFIG_PATH=${HOME}/.config/rgrc

export PATH=/usr/bin:/bin:/usr/sbin:/sbin
prepend_to_path \
	"${basedir}"/extra/gimme \
	/usr/local/sbin \
	/usr/local/bin \
	"${HOME}"/.cargo/bin \
	"${HOME}"/.local/bin \
	"${basedir}"/bin \
	"${GOBIN}"

source "${basedir}"/extra/brew

cond_source "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
cond_source "${HOME}/.gimme/envs/gotip.env"
cond_source "${basedir}/extra/z/z.sh"

source "${basedir}"/extra/virtualenv
source "${basedir}"/extra/gpg-agent

source "${basedir}"/extra/git
source "${basedir}"/extra/go
source "${basedir}"/extra/mail
source "${basedir}"/extra/ocaml
source "${basedir}"/extra/neovim
source "${basedir}"/extra/rclone
source "${basedir}"/extra/poetry
source "${basedir}"/extra/alacritty

cond_source "${basedir}/extra/local-functions"
cond_source "${basedir}/extra/$(uname -s)-functions"

export NO_COLOR=1
export PS1="％ " PS2="\\ "

if command -v fnm &>/dev/null; then
	eval "$(fnm env)"
fi

source "${basedir}"/extra/tmux

fpath=(/usr/local/share/zsh-completions ~/.zfunc $fpath)
export ZLE_SPACE_SUFFIX_CHARS=$'|&'

autoload -Uz compinit && compinit -u

export HISTFILE="$HOME/.history"
export HISTSIZE=1234567890
export SAVEHIST=$HISTSIZE

setopt noautomenu
setopt nomenucomplete

setopt BANG_HIST
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

bindkey -e

autoload -U edit-command-line
zle -N edit-command-line
bindkey '^xe' edit-command-line
bindkey '^x^e' edit-command-line

alias bump_dotfiles="cd ${basedir} && git pull && git submodule update --init --recursive && bin/setup && cd -"

source "${basedir}"/extra/fzf
unset basedir
