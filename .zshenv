FSOUZA_DOTFILES_DIR=${FSOUZA_DOTFILES_DIR:-$(dirname "$(readlink "${(%):-%N}")")}

export FSOUZA_DOTFILES_DIR
export ZDOTDIR=${FSOUZA_DOTFILES_DIR}/zsh
