#!/usr/bin/env bash

set -euo pipefail

basedir=$(
	cd "$(dirname "${0}")"/..
	pwd -P
)

function get_taps() {
	for tap in $(brew tap); do
		user=${tap%%/*}
		repo=${tap##*/}
		echo "${tap}" "$(git -C "${HOMEBREW_PREFIX}/Homebrew/Library/Taps/${user}/homebrew-${repo}" remote get-url origin)"
	done
}

brew info --installed --json | jq -rf "${basedir}"/extra/brew-info.jq >"$1"

get_taps >"${1}-tap"
if [[ ${OSTYPE} == darwin* ]]; then
	brew list --cask >"${1}-cask"
	mas list >"${1}-mas"
fi
