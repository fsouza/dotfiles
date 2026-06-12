#!/usr/bin/env zsh

set -euo PIPEFAIL

brew update
brew upgrade -y

brew cleanup -s --prune 3
if [[ ${OSTYPE} == darwin* ]]; then
	brew services cleanup || true
fi
