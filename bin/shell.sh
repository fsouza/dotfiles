#!/usr/bin/env bash

set -euo pipefail

exec arch -arch "$(uname -m)" /bin/zsh "$@"
