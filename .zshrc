# on mac, coreutils is needed to get realpath.
basedir=$(dirname $(realpath ${(%):-%N}))
source ${basedir}/extra/init-functions

autoload -U compinit && compinit

export RBENV_ROOT=${HOME}/.rbenv
export MANPATH=/usr/share/man:/usr/local/share/man:/home/linuxbrew/.linuxbrew/share/man:${basedir}/extra/z
export GOBIN=$HOME/bin GOPATH=$HOME/.go GIMME_SILENT_ENV=1 GIMME_TYPE=binary

export PATH=/usr/bin:/bin:/usr/sbin:/sbin
prepend_to_path \
	${basedir}/extra/gimme \
	/usr/local/sbin \
	/usr/local/bin \
	/home/linuxbrew/.linuxbrew/sbin \
	/home/linuxbrew/.linuxbrew/bin \
	${HOME}/.cargo/bin \
	${HOME}/.fnm \
	${RBENV_ROOT}/shims \
	${HOME}/.local/bin \
	${basedir}/bin \
	${GOBIN}

export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_EMOJI=1
export HOMEBREW_NO_GITHUB_API=1

export EDITOR=nvim PAGER=less MANPAGER=less

cond_source "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
cond_source "${HOME}/.gimme/envs/gotip.env"
cond_source "${basedir}/extra/z/z.sh"

source ${basedir}/extra/brew
source ${basedir}/extra/virtualenv
source ${basedir}/extra/gpg-agent

source ${basedir}/extra/git
source ${basedir}/extra/go
source ${basedir}/extra/mail
source ${basedir}/extra/ocaml
source ${basedir}/extra/neovim
source ${basedir}/extra/rclone

cond_source "${basedir}/extra/local-functions"
cond_source "${basedir}/extra/${OS_NAME}-functions"

export PS1="％ " PS2="\\ "

if command -v opam &>/dev/null; then
	eval "$(opam env)"
fi

if command -v fnm &>/dev/null; then
	eval "$(fnm env --multi)"
fi

if command -v rg &>/dev/null; then
	export FZF_DEFAULT_COMMAND="rg -l --hidden -g '!.git' -g '!.hg' '.*'"
fi

source ${basedir}/extra/tmux
unset basedir

fpath=(/usr/local/share/zsh-completions $fpath)
export ZLE_SPACE_SUFFIX_CHARS=$'|&'

export HISTFILE="$HOME/.history"
export HISTSIZE=1234567890
export SAVEHIST=$HISTSIZE

setopt noautomenu
setopt nomenucomplete

setopt BANG_HIST
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

bindkey -e
