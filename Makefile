SHELL := zsh
NVIM_CACHE_DIR := $(shell nvim --clean -l - <<<'print(vim.fn.stdpath("cache"))' 2>&1)
NVIM_CONFIG_DIR := $(shell nvim --clean -l - <<<'print(vim.fn.stdpath("config"))' 2>&1)
NVIM_DATA_DIR := $(shell nvim --clean -l - <<<'print(vim.fn.stdpath("data"))' 2>&1)
NVIM_STATE_DIR := $(shell nvim --clean -l - <<<'print(vim.fn.stdpath("state"))' 2>&1)
LUA := $(NVIM_CACHE_DIR)/hr/bin/lua
PYTHON ?= python3.12

.PHONY: all
all: bootstrap-nvim install update-treesitter kill-daemons clear-logs

.PHONY: bootstrap-nvim
bootstrap-nvim:
	${FSOUZA_DOTFILES_CACHE_DIR}/bin/nvim-bootstrap

.PHONY: update-treesitter
update-treesitter:
	nvim --headless -E +'TSUpdateSync' +'quit'

.PHONY: kill-daemons
kill-daemons:
	pkill prettierd || true
	pkill eslint_d || true

.PHONY: clear-logs
clear-logs:
	:> $(NVIM_STATE_DIR)/lsp.log

FILES_TO_INSTALL := $(shell git ls-files --cached --others -- '*.lua' '*.vim' '*.scm' | grep -Ev '^build|nvim/vendor/')
FILES_INSTALLED := $(patsubst %,build/%,$(FILES_TO_INSTALL))

.PHONY: install
install: install-nvim-site install-nvim-init.lua install-hammerspoon

.PHONY: install-nvim-site
install-nvim-site: site
	rsync -avr build/nvim/ $(NVIM_DATA_DIR)/site/

.PHONY: minimum-install
minimum-install: site install-nvim-init.lua
	rsync -avr --exclude=plugin build/nvim/ $(NVIM_DATA_DIR)/site/

.PHONY: install-nvim-init.lua
install-nvim-init.lua: build/nvim/init.lua
	mkdir -p $(NVIM_CONFIG_DIR)
	install -v -C build/nvim/init.lua $(NVIM_CONFIG_DIR)/init.lua

.PHONY: site
site: build
	mkdir -p $(NVIM_DATA_DIR)

.PHONY: install-hammerspoon
install-hammerspoon: build
	rsync -avr build/hammerspoon/ $(HOME)/.hammerspoon/

.PHONY: rebuild
rebuild: clean build

.PHONY:
clean:
	rm -rf build

.PHONY: uninstall
uninstall: clean-site clean-hammerspoon uninstall-nvim-config

.PHONY: clean-site
clean-site: clean
	rm -rf $(NVIM_DATA_DIR)/site

.PHONY: clean-hammerspoon
clean-hammerspoon:
	rm -rf ~/.hammerspoon

.PHONY: uninstall-nvim-config
uninstall-nvim-config:
	rm -rf $(NVIM_CONFIG_DIR)

build: $(FILES_TO_INSTALL) $(FILES_INSTALLED)

build/%.lua: %.lua
	@ mkdir -p $(dir $@)
	install $< $@

build/%.vim: %.vim
	@ mkdir -p $(dir $@)
	install $< $@

build/%.scm: %.scm
	@ mkdir -p $(dir $@)
	install $< $@
