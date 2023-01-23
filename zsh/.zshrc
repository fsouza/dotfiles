autoload -U add-zsh-hook

source ${FSOUZA_DOTFILES_DIR}/extra/init-functions

mkdir -p ~/.cache/{go,node,zsh}

export EDITOR=vim PAGER=less MANPAGER=less
export RIPGREP_CONFIG_PATH=${HOME}/.config/rgrc
export LESSHISTFILE=${HOME}/.cache/lesshst
export NODE_REPL_HISTORY=${HOME}/.cache/node/history

export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin
source "${FSOUZA_DOTFILES_DIR}"/extra/brew

prepend_to_path \
	${HOME}/.cargo/bin \
	${HOME}/.local/bin \
	${HOME}/.dotnet/tools \
	${FSOUZA_DOTFILES_DIR}/bin

export MANPATH=${HOME}/.local/share/man${MANPATH+:${MANPATH}}

if command -v fnm &>/dev/null; then
	eval "$(fnm env)"
fi

local extras=(virtualenv z git gh go java mail ocaml neovim rclone ruby tmux)
local extras_skip=( ${FSOUZA_EXTRAS_SKIP[@]} )
for extra in ${extras[@]}; do
	if ! (($extras_skip[(Ie)$extra])); then
		source ${FSOUZA_DOTFILES_DIR}/extra/${extra}
	fi
done
unset extras
unset extras_skip

cond_source ${FSOUZA_DOTFILES_DIR}/extra/local-functions
cond_source ${FSOUZA_DOTFILES_DIR}/extra/"$(uname -s)"-functions

fpath=(${HOMEBREW_PREFIX}/share/zsh-completions ~/.cache/zsh/zfunc $fpath)
export ZLE_SPACE_SUFFIX_CHARS=$'|&'

autoload -Uz compinit && compinit -d ${HOME}/.cache/zsh/zcompdump -u

export HISTFILE=${HOME}/.cache/zsh/history
export HISTSIZE=1234567890
export SAVEHIST=${HISTSIZE}
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

alias bump_dotfiles="git -C ${FSOUZA_DOTFILES_DIR} pull && ${FSOUZA_DOTFILES_DIR}/bootstrap/setup"

source ${FSOUZA_DOTFILES_DIR}/extra/fzf

PROMPT="％ " PROMPT2="\\ "

ulimit -n 8192

export FSOUZA_DOTFILES_DIR
