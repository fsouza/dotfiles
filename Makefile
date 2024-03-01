SHELL := zsh
NVIM_CACHE_DIR := $(shell nvim --clean -l - <<<'print(vim.fn.stdpath("cache"))' 2>&1)
NVIM_CONFIG_DIR := $(shell nvim --clean -l - <<<'print(vim.fn.stdpath("config"))' 2>&1)
NVIM_DATA_DIR := $(shell nvim --clean -l - <<<'print(vim.fn.stdpath("data"))' 2>&1)
NVIM_STATE_DIR := $(shell nvim --clean -l - <<<'print(vim.fn.stdpath("state"))' 2>&1)
LUA := $(NVIM_CACHE_DIR)/hr/bin/lua
FENNEL := $(NVIM_CACHE_DIR)/hr/bin/fennel
PYTHON ?= python3.12

.PHONY: all
all: bootstrap-nvim install update-treesitter kill-daemons clear-logs

.PHONY: bootstrap-nvim
bootstrap-nvim:
	env MISE_PYTHON_COMPILE=1 ${FSOUZA_DOTFILES_DIR}/tools/bin/nvim-bootstrap

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

FNL_FILES := $(shell git ls-files --cached --others -- '*.fnl' | grep -Ev 'scripts/.+\.fnl' | grep -Ev 'macros/.+\.fnl')
LUA_FILES := $(patsubst %.fnl,build/%.lua,$(FNL_FILES))
NON_LUA_FILES := $(shell git ls-files --cached --others -- '*.vim' '*.scm' | grep -Ev '^build/')
TARGET_NON_LUA_FILES := $(patsubst %,build/%,$(NON_LUA_FILES))

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

build: scripts/compile.lua $(LUA_FILES) $(TARGET_NON_LUA_FILES)

build/%.lua: %.fnl
	$(LUA) scripts/compile.lua --output $@ $<

build/%.vim: %.vim
	@ mkdir -p $(dir $@)
	install -C $< $@

build/%.scm: %.scm
	@ mkdir -p $(dir $@)
	install -C $< $@

scripts/compile.lua: scripts/compile.fnl
	$(eval TMP_FILE := $(shell mktemp))
	$(FENNEL) -c $< >$(TMP_FILE)
	mv $(TMP_FILE) $@

.PHONY: fnlfmt
fnlfmt:
	git ls-files -z --cached --others -- '*.fnl' | env PATH=$(NVIM_CACHE_DIR)/hr/bin:${PATH} xargs -0 -n 1 $(NVIM_CACHE_DIR)/fnlfmt/fnlfmt --fix
