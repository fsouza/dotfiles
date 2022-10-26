NVIM_CACHE_DIR := $(shell nvim --clean --headless -E -u NORC -R +'echo stdpath("cache")' +q 2>&1)
NVIM_CONFIG_DIR := $(shell nvim --clean --headless -E -u NORC -R +'echo stdpath("config")' +q 2>&1)
NVIM_DATA_DIR := $(shell nvim --clean --headless -E -u NORC -R +'echo stdpath("data")' +q 2>&1)
NVIM_STATE_DIR := $(shell nvim --clean --headless -E -u NORC -R +'echo stdpath("state")' +q 2>&1)
LUA := $(NVIM_CACHE_DIR)/hr/bin/lua
FENNEL := $(NVIM_CACHE_DIR)/hr/bin/fennel
PYTHON ?= python3.11

.PHONY: all
all: bootstrap-nvim update-paq update-treesitter kill-daemons clear-logs

.PHONY: bootstrap-nvim
bootstrap-nvim:
	$(PYTHON) nvim/scripts/bootstrap.py

.PHONY: update-paq
update-paq: install
	env BOOTSTRAP_PAQ=1 nvim --headless -E +'autocmd User PaqDoneSync quit' || true

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

FNL_FILES := $(shell fd --type f '.+\.fnl' | grep -Ev 'scripts/.+\.fnl' | grep -Ev 'macros/.+\.fnl' | sd '^./' '')
LUA_FILES := $(patsubst %.fnl,build/%.lua,$(FNL_FILES))
VIM_FILES := $(shell fd --type f '.+\.vim' | sd '^./' '')
TARGET_VIM_FILES := $(patsubst %,build/%,$(VIM_FILES))

.PHONY: install
install: install-nvim-site install-nvim-init.lua install-hammerspoon

.PHONY: install-site
install-nvim-site: build
	@ mkdir -p $(NVIM_DATA_DIR)/site
	cp -prv build/nvim/* $(NVIM_DATA_DIR)/site

.PHONY: install-nvim-init.lua
install-nvim-init.lua: build/nvim/init.lua
	@ mkdir -p $(NVIM_CONFIG_DIR)
	cp -p build/nvim/init.lua $(NVIM_CONFIG_DIR)

.PHONY: install-hammerspoon
install-hammerspoon: build
	@ mkdir -p ~/.hammerspoon
	cp -p build/hammerspoon/init.lua ~/.hammerspoon/init.lua

.PHONY: rebuild
rebuild: clean build

.PHONY:
clean:
	rm -rf build

.PHONY: uninstall
uninstall: clean-site clean-hammerspoon

.PHONY: clean-site
clean-site: clean
	rm -rf $(NVIM_DATA_DIR)/site

.PHONY: clean-hammerspoon
clean-hammerspoon:
	rm -rf ~/.hammerspoon

build: scripts/compile.lua $(LUA_FILES) $(TARGET_VIM_FILES)

build/%.lua: %.fnl
	$(LUA) scripts/compile.lua --output $@ $<

build/%.vim: %.vim
	@ mkdir -p $(dir $@)
	cp $< $@

scripts/compile.lua: scripts/compile.fnl
	$(eval TMP_FILE := $(shell mktemp))
	$(FENNEL) -c $< >$(TMP_FILE)
	mv $(TMP_FILE) $@

.PHONY: nvim-tests
nvim-tests:
	nvim --headless -c 'autocmd User PluginReady ++once lua require("fsouza.plugin.plenary-tests")["run-tests"]()'

.PHONY: nvim-lint
nvim-lint: nvim-selene nvim-stylua


.PHONY: nvim-selene
nvim-selene:
	cd nvim && selene .

.PHONY: nvim-stylua
nvim-stylua:
	cd nvim && stylua --check .
