basedir=$(dirname "$(readlink "${(%):-%N}")")
source "${basedir}"/extra/init-functions

mkdir -p ~/.cache/{go,node,zsh}

export EDITOR=vim PAGER=less MANPAGER=less
export RIPGREP_CONFIG_PATH=${HOME}/.config/rgrc
export LESSHISTFILE=${HOME}/.cache/lesshst
export NODE_REPL_HISTORY=${HOME}/.cache/node/history

export PATH=/usr/bin:/bin:/usr/sbin:/sbin
source "${basedir}"/extra/brew

prepend_to_path \
	"${HOME}"/.cargo/bin \
	"${HOME}"/.local/bin \
	"${HOME}/.dotnet/tools" \
	"${basedir}"/bin

export MANPATH="${HOME}/.local/share/man${MANPATH+:$MANPATH}:"

if command -v fnm &>/dev/null; then
	eval "$(fnm env)"
fi

cond_source "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"

source "${basedir}"/extra/virtualenv

source "${basedir}"/extra/z
source "${basedir}"/extra/git
source "${basedir}"/extra/go
source "${basedir}"/extra/mail
source "${basedir}"/extra/ocaml
source "${basedir}"/extra/neovim
source "${basedir}"/extra/alacritty
source "${basedir}"/extra/rclone
source "${basedir}"/extra/zig

cond_source "${basedir}/extra/local-functions"
cond_source "${basedir}/extra/$(uname -s)-functions"

source "${basedir}"/extra/tmux

fpath=(${HOMEBREW_PREFIX}/share/zsh-completions ~/.cache/zsh/zfunc $fpath)
export ZLE_SPACE_SUFFIX_CHARS=$'|&'

autoload -Uz compinit && compinit -d "${HOME}/.cache/zsh/zcompdump" -u

export HISTFILE="$HOME/.cache/zsh/history"
export HISTSIZE=1234567890
export SAVEHIST=$HISTSIZE
export NO_COLOR=1

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

autoload -U select-word-style
select-word-style bash

alias bump_dotfiles="git -C ${basedir} pull && ${basedir}/bootstrap/setup && upgrade_virtualenv"

source "${basedir}"/extra/fzf
unset basedir

PROMPT="％ " PROMPT2="\\ "
