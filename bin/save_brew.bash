#!/usr/bin/env bash

set -euo pipefail

brew leaves --installed-on-request >"$1"

get_taps >"${1}-tap"
if [[ ${OSTYPE} == darwin* ]]; then
	brew list --cask >"${1}-cask"
	mas list >"${1}-mas"
fi
