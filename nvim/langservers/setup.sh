#!/usr/bin/env bash

set -euo pipefail

function _clone_or_update() {
	repo=$1
	path=$2
	version=${3:-}

	if ! [ -d "${path}" ]; then
		git clone --recurse-submodules "${repo}" "${path}"
	elif [ -z "${version}" ]; then
		git -C "${path}" pull
		git -C "${path}" submodule update --init --recursive
	else
		git -C "${path}" fetch
		git -C "${path}" checkout "${version}"
		git -C "${path}" submodule update --init --recursive
	fi
}

function install_ocaml_lsp() {
	if ! command -v opam &>/dev/null; then
		echo skipping ocaml-lsp
		return
	fi
	opam update -y &&
		opam install -y ocaml-lsp-server ocamlformat
}

function install_servers_from_npm() {
	if ! command -v fnm &>/dev/null; then
		echo skipping npm
		return
	fi
	fnm install v16
	fnm exec --using=v16 npx --yes yarn install --frozen-lockfile
}

function _go_install() {
	if ! command -v go &>/dev/null; then
		echo skipping "${@}"
		return
	fi
	env GOBIN="${cache_dir}/bin" go install "${@}"
}

function install_gopls() {
	if ! command -v go &>/dev/null; then
		echo skipping gopls
		return
	fi
	dir="${cache_dir}/tools"
	_clone_or_update https://github.com/golang/tools.git "${dir}" &&
		pushd "${dir}/gopls" &&
		env GOBIN="${cache_dir}/bin" go install
}

function install_shfmt() {
	_go_install mvdan.cc/sh/v3/cmd/shfmt@master
}

function install_efm() {
	_go_install github.com/mattn/efm-langserver@master
}

cache_dir=${1}
exit_status=0

function process_child() {
	if [[ ${1} -gt 0 ]]; then
		exit_status=${1}
	fi
}

trap 'process_child $?' CHLD

if [ -z "${cache_dir}" ]; then
	echo "the cache dir is required. Please provide it as a positional parameter" >&2
	exit 2
fi

pushd "$(dirname "${0}")"
mkdir -p "${cache_dir}"
install_servers_from_npm &
install_ocaml_lsp &
install_gopls &
install_shfmt &
install_efm &
wait
popd

exit "${exit_status}"
