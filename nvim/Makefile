NVIM_CACHE_DIR := $(shell nvim --clean --headless -E -u NORC -R +'echo stdpath("cache")' +q 2>&1)

FENNEL := $(if $(shell command -v fennel 2>/dev/null), fennel, $(NVIM_CACHE_DIR)/hr/bin/fennel)

.PHONY: all
all: bootstrap update-paq kill-daemons clear-logs

.PHONY: bootstrap
bootstrap:
	python3.9 scripts/bootstrap.py

.PHONY: update-paq
update-paq: compile
	env BOOTSTRAP_PAQ=1 nvim --headless -E +'lua vim.loop.new_timer():start(10000, 0, vim.schedule_wrap(function() vim.cmd("qa") end))' || true

.PHONY: kill-daemons
kill-daemons:
	pkill prettierd || true
	pkill eslint_d || true

.PHONY: clear-logs
clear-logs:
	:> $(NVIM_CACHE_DIR)/lsp.log

FNL_FILES := $(shell find . -name '*.fnl' | sed -e 's;./;;')
LUA_FILES := $(patsubst %.fnl,%.lua,$(patsubst fnl/%.fnl,lua/%.lua,$(FNL_FILES)))

.PHONY: compile
compile: $(LUA_FILES)

%.lua: %.fnl
	@ mkdir -p $(dir $@)
	$(FENNEL) -c $< > $@

lua/%.lua: fnl/%.fnl
	@ mkdir -p $(dir $@)
	$(FENNEL) -c $< > $@
