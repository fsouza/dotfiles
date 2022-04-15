NVIM_CACHE_DIR := $(shell nvim --clean --headless -E -u NORC -R +'echo stdpath("cache")' +q 2>&1)
NVIM_CONFIG_DIR := $(shell nvim --clean --headless -E -u NORC -R +'echo stdpath("config")' +q 2>&1)
NVIM_DATA_DIR := $(shell nvim --clean --headless -E -u NORC -R +'echo stdpath("data")' +q 2>&1)
FENNEL := $(if $(shell command -v fennel 2>/dev/null),fennel,$(NVIM_CACHE_DIR)/hr/bin/fennel)
PYTHON ?= python3.10

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
	:> $(NVIM_CACHE_DIR)/lsp.log

FNL_FILES := $(shell find . -name '*.fnl' | grep -v 'macros/.*\.fnl' | sed -e 's;./;;')
LUA_FILES := $(patsubst %.fnl,build/%.lua,$(FNL_FILES))
VIM_FILES := $(shell find . -name '*.vim' | sed -e 's;./;;' | grep -v '^build/')
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

build: $(LUA_FILES) $(TARGET_VIM_FILES)

build/%.lua: %.fnl
	env FENNEL=$(FENNEL) $(PYTHON) scripts/compile.py $< $@

build/%.vim: %.vim
	@ mkdir -p $(dir $@)
	cp $< $@

.PHONY: nvim-tests
nvim-tests:
	nvim --headless -c 'autocmd User PluginReady ++once RunTests'
