SHELL := zsh
NVIM_CONFIG_DIR ?= $(shell nvim --clean -l - <<<'print(vim.fn.stdpath("config"))' 2>&1)
NVIM_STATE_DIR ?= $(shell nvim --clean -l - <<<'print(vim.fn.stdpath("state"))' 2>&1)
NVIM_CONFIG_RSYNC_EXCLUDE := --exclude=langservers --exclude=vendor
PYTHON ?= python3.12

.PHONY: all
all: install kill-daemons clear-logs

.PHONY: kill-daemons
kill-daemons:
	pkill prettierd || true
	pkill eslint_d || true

.PHONY: clear-logs
clear-logs:
	:> $(NVIM_STATE_DIR)/lsp.log

.PHONY: install
install: install-nvim-config install-hammerspoon

.PHONY: minimum-install
minimum-install: site install-nvim-init.lua
	rsync -avr --exclude=plugin $(NVIM_CONFIG_RSYNC_EXCLUDE) --delete nvim/ $(NVIM_CONFIG_DIR)

.PHONY: install-nvim-config
install-nvim-config:
	mkdir -p $(NVIM_CONFIG_DIR)
	rsync -avr --delete $(NVIM_CONFIG_RSYNC_EXCLUDE) nvim/ $(NVIM_CONFIG_DIR)/

.PHONY: install-hammerspoon
install-hammerspoon:
ifeq ($(shell uname -s),Darwin)
	rsync -avr --delete hammerspoon/ $(HOME)/.hammerspoon/
endif

.PHONY: uninstall
uninstall: uninstall-nvim-config clean-hammerspoon

.PHONY: clean-hammerspoon
clean-hammerspoon:
	rm -rf ~/.hammerspoon

.PHONY: uninstall-nvim-config
uninstall-nvim-config:
	rm -rf $(NVIM_CONFIG_DIR)
