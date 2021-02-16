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
		git -C "${path}" submodules update --init --recursive
	else
		git -C "${path}" fetch
		git -C "${path}" checkout "${version}"
		git -C "${path}" submodules update --init --recursive
	fi
}

function _create_opam_switch_if_needed() {
	if [[ $(opam switch show) != "${PWD}" ]]; then
		opam switch create . ocaml-base-compiler.4.11.1 --with-test --yes
	fi
}

function install_ocaml_lsp() {
	if ! command -v opam &>/dev/null; then
		echo skipping ocaml-lsp
		return
	fi
	path="${cache_dir}/ocaml-lsp"
	_clone_or_update https://github.com/ocaml/ocaml-lsp.git "${path}" &&
		pushd "${path}" &&
		_create_opam_switch_if_needed &&
		opam exec -- opam update -y &&
		opam exec -- opam install -y . &&
		opam exec -- dune build --root . &&
		popd
}

function install_rust_analyzer() {
	local suffix
	if ! command -v cargo &>/dev/null; then
		echo skipping rust-analyzer
		return
	fi
	if [[ $OSTYPE == darwin* ]]; then
		suffix=mac
	elif [[ $OSTYPE == linux* ]]; then
		suffix=linux
	fi
	mkdir -p "${cache_dir}/bin"
	curl -sLo "${cache_dir}/bin/rust-analyzer" "https://github.com/rust-analyzer/rust-analyzer/releases/download/nightly/rust-analyzer-${suffix}"
	chmod +x "${cache_dir}/bin/rust-analyzer"
}

function install_servers_from_npm() {
	npm ci
}

function _go_install() {
	if ! command -v go &>/dev/null; then
		echo skipping "${@}"
		return
	fi
	(
		cd /tmp && env GO111MODULE=on GOBIN="${cache_dir}/bin" go get "${@}"
	)
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

function install_lua_lsp() {
	if ! command -v ninja &>/dev/null; then
		echo skipping lua-lsp
		return
	fi
	if [[ $OSTYPE == darwin* ]]; then
		ninja_file=ninja/macos.ninja
	elif [[ $OSTYPE == linux* ]]; then
		ninja_file=ninja/linux.ninja
	fi
	path=${cache_dir}/lua-language-server
	_clone_or_update https://github.com/sumneko/lua-language-server "${path}" &&
		pushd "${path}" &&
		cd 3rd/luamake &&
		ninja -f "${ninja_file}" &&
		cd ../.. &&
		./3rd/luamake/luamake rebuild &&
		popd
}

function install_zls() {
	if ! command -v zig &>/dev/null; then
		echo skipping zls
		return
	fi
	path=${cache_dir}/zls
	_clone_or_update https://github.com/zigtools/zls.git "${path}" &&
		pushd "${path}" &&
		zig build -Drelease-safe &&
		echo '{"enable_snippets":true,"warn_style":true,"enable_semantic_tokens":false,"operator_completions":false}' >zig-cache/bin/zls.json &&
		popd
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
install_rust_analyzer &
install_gopls &
install_lua_lsp &
install_shfmt &
install_efm &
install_zls &
wait
popd

exit "${exit_status}"
