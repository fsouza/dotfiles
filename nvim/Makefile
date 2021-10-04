NVIM_CACHE_DIR := $(shell nvim --clean --headless -E -u NORC -R +'echo stdpath("cache")' +q 2>&1)
NVIM_CONFIG_DIR := $(shell nvim --clean --headless -E -u NORC -R +'echo stdpath("config")' +q 2>&1)
NVIM_DATA_DIR := $(shell nvim --clean --headless -E -u NORC -R +'echo stdpath("data")' +q 2>&1)
FENNEL := $(if $(shell command -v fennel 2>/dev/null),fennel,$(NVIM_CACHE_DIR)/hr/bin/fennel)

.PHONY: all
all: bootstrap gen-init-lua update-paq kill-daemons clear-logs

.PHONY: bootstrap
bootstrap:
	python3.9 scripts/bootstrap.py

.PHONY: update-paq
update-paq: install-site
	env BOOTSTRAP_PAQ=1 nvim --headless -E +'lua vim.loop.new_timer():start(10000, 0, vim.schedule_wrap(function() vim.cmd("qa") end))' || true

.PHONY: kill-daemons
kill-daemons:
	pkill prettierd || true
	pkill eslint_d || true

.PHONY: clear-logs
clear-logs:
	:> $(NVIM_CACHE_DIR)/lsp.log

FNL_FILES := $(shell find . -name '*.fnl' | grep -v 'macros/.*\.fnl' | sed -e 's;./;;')
LUA_FILES := $(patsubst %.fnl,build/%.lua,$(FNL_FILES))

.PHONY: install-site
install-site: build
	@ mkdir -p $(NVIM_DATA_DIR)/site
	cp -prv build/* $(NVIM_DATA_DIR)/site

.PHONY: rebuild
rebuild: clean build

.PHONY:
clean:
	rm -rf build

.PHONY: clean-site
clean-site: clean
	rm -rf $(NVIM_DATA_DIR)/site

build: $(LUA_FILES)

build/%.lua: %.fnl
	env FENNEL=$(FENNEL) python3.9 scripts/compile.py $< $@

.PHONY: gen-init-lua
gen-init-lua:
	@ mkdir -p $(NVIM_CONFIG_DIR)
	echo 'require("fsouza")' > $(NVIM_CONFIG_DIR)/init.lua
