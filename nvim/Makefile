mkfile_path := $(realpath $(lastword $(MAKEFILE_LIST)))
mkfile_dir := $(dir $(mkfile_path))

LUACHECK := $(if $(shell command -v luacheck 2>/dev/null), luacheck, $(shell nvim --clean --headless -E -u NORC -R +'echo stdpath("cache")' +q 2>&1)/hr/bin/luacheck)

LUAFORMAT := $(if $(shell command -v lua-format 2>/dev/null), lua-format, $(shell nvim --clean --headless -E -u NORC -R +'echo stdpath("cache")' +q 2>&1)/hr/bin/lua-format)

MACOSX_DEPLOYMENT_TARGET ?= 10.15

.PHONY: all
all: luacheck lua-format

.PHONY: bootstrap
bootstrap:
	git -C $(mkfile_dir) submodule update --init --recursive
	cd $(mkfile_dir) && env MACOSX_DEPLOYMENT_TARGET=$(MACOSX_DEPLOYMENT_TARGET) NVIM_BOOTSTRAP=1 nvim --headless -E -u NORC +'set rtp+=$(mkfile_dir)' +'luafile scripts/bootstrap.lua' +qa
	make -f $(mkfile_path) update-paq kill-daemons

.PHONY: update-paq
update-paq:
	env BOOTSTRAP_PAQ=1 nvim --headless -E +'PaqSync' +'lua vim.loop.new_timer():start(10000, 0, vim.schedule_wrap(function() vim.cmd("qa") end))' || true

.PHONY: kill-daemons
kill-daemons:
	pkill prettierd || true
	pkill eslint_d || true

.PHONY: luacheck
luacheck:
	cd $(mkfile_dir) && $(LUACHECK) --no-color lua

.PHONY: lua-format
lua-format:
	cd $(mkfile_dir) && git ls-files -- '*.lua' '*.rockspec' | grep -v ^pack | xargs $(LUAFORMAT) -i
