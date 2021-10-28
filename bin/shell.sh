#!/usr/bin/env bash

# Note: this script requires bash 4+. If I run into issues, I can update it to
# make it compatible with Bash 3. The idea is that this script is temporary
# though, so hopefully not needed :)

set -euo pipefail

function get_arch {
	# Alacritty doesn't have a universal binary yet, so I actually want to
	# run zsh in arm64 on Apple Silicon, even if Alacritty is running in
	# emulated mode. Once Alacritty 0.10.0 is out, I can remove this hack
	# (alternatively, I could compile alacritty from master, but I'm not
	# interested :)
	local arch proc_translated
	arch=$(uname -m)
	if [[ $arch == "x86_64" ]]; then
		proc_translated=$(sysctl -n sysctl.proc_translated 2>/dev/null || true)
		if [[ $proc_translated == "1" ]]; then
			echo "arm64"
			return 0
		fi
	fi
	echo "${arch}"
}

exec arch -arch "$(get_arch)" /bin/zsh "$@"
