local vcmd = vim.cmd
local vfn = vim.fn

local cache_dir = vfn.stdpath('cache')
local data_dir = vfn.stdpath('data')

local helpers = require('fsouza.lib.nvim_helpers')

_G.prequire = function(module)
  local ok, mod = pcall(require, module)
  if not ok then
    return nil
  end
  return mod
end

local function initial_mappings()
  helpers.create_mappings({
    n = {{lhs = 'Q'; rhs = ''}; {lhs = '<Space>'; rhs = ''}; {lhs = '<c-t>'; rhs = ''}};
  })
  vim.g.mapleader = ' '
end

local function hererocks()
  local lua_version = string.gsub(_VERSION, 'Lua ', '')
  local hererocks_path = cache_dir .. '/hr'
  local share_path = hererocks_path .. '/share/lua/' .. lua_version
  local lib_path = hererocks_path .. '/lib/lua/' .. lua_version
  package.path = package.path .. ';' .. share_path .. '/?.lua' .. ';' .. share_path ..
                   '/?/init.lua'
  package.cpath = package.cpath .. ';' .. lib_path .. '/?.so'
end

local function global_vars()
  vim.g.netrw_home = data_dir
  vim.g.netrw_banner = 0
  vim.g.netrw_liststyle = 3
  vim.g.fzf_command_prefix = 'Fzf'
  vim.g.fzf_layout = {window = {width = 0.9; height = 0.6}}
  vim.g.polyglot_disabled = {'markdown'; 'sensible'; 'autoindent'}
  vim.g.user_emmet_mode = 'i'
  vim.g.user_emmet_leader_key = [[<C-x>]]
  vim.g.VM_maps = {['Find Under'] = ''}
  vim.g.VM_show_warnings = 0
  vim.g.wordmotion_extra = {
    [=[\([a-f]\+[0-9]\+\([a-f]\|[0-9]\)*\)\+]=];
    [=[\([0-9]\+[a-f]\+\([0-9]\|[a-f]\)*\)\+]=];
    [=[\([A-F]\+[0-9]\+\([A-F]\|[0-9]\)*\)\+]=];
    [=[\([0-9]\+[A-F]\+\([0-9]\|[A-F]\)*\)\+]=];
  }
end

local function ui_options()
  vim.o.cursorline = true
  vim.o.cursorlineopt = 'number'
  vim.o.termguicolors = true
  vim.o.showcmd = false
  vim.o.laststatus = 0
  vim.o.ruler = true
  vim.o.rulerformat = [[%-14.(%l,%c   %o%)]]
  vim.o.guicursor = 'a:block'
  vim.o.mouse = ''
  vim.o.shiftround = true
  vim.o.shortmess = 'filnxtToOFIc'
  vim.o.number = true
  vim.o.relativenumber = true
  require('fsouza.color').enable()
end

local function global_options()
  vim.o.completeopt = 'menuone,noinsert,noselect'
  vim.o.hidden = true
  vim.o.backspace = 'indent,eol,start'
  vim.o.hlsearch = false
  vim.o.incsearch = true
  vim.o.wildmenu = true
  vim.o.wildmode = 'list:longest'
  vim.o.smarttab = true
  vim.o.backup = false
  vim.o.inccommand = 'nosplit'
  vim.o.jumpoptions = 'stack'
  vim.o.scrolloff = 2
  vim.o.autoindent = true
  vim.o.smartindent = true
  vim.o.swapfile = false
  vim.o.undofile = true
  vim.o.joinspaces = false
end

local function folding()
  vim.o.foldlevelstart = 99
  vcmd([[set foldmethod=indent]])
end

local function global_mappings()
  local rl_bindings = {
    {lhs = '<c-a>'; rhs = '<home>'; opts = {noremap = true}};
    {lhs = '<c-e>'; rhs = '<end>'; opts = {noremap = true}};
    {lhs = '<c-f>'; rhs = '<right>'; opts = {noremap = true}};
    {lhs = '<c-b>'; rhs = '<left>'; opts = {noremap = true}};
    {lhs = '<c-p>'; rhs = '<up>'; opts = {noremap = true}};
    {lhs = '<c-n>'; rhs = '<down>'; opts = {noremap = true}};
    {lhs = '<c-d>'; rhs = '<del>'; opts = {noremap = true}};
    {lhs = '<m-p>'; rhs = '<up>'; opts = {noremap = true}};
    {lhs = '<m-n>'; rhs = '<down>'; opts = {noremap = true}};
    {lhs = '<m-b>'; rhs = '<s-left>'; opts = {noremap = true}};
    {lhs = '<m-f>'; rhs = '<s-right>'; opts = {noremap = true}};
    {lhs = '<m-d>'; rhs = '<s-right><c-w>'; opts = {noremap = true}};
  }
  local maps = {c = rl_bindings; o = rl_bindings}
  helpers.create_mappings(maps)
end

do
  local schedule = vim.schedule
  initial_mappings()
  hererocks()

  schedule(function()
    global_options()
    global_mappings()
  end)

  ui_options()
  folding()
  global_vars()

  if vim.env.NVIM_PLUG then
    require('fsouza.vim-plug').setup()
    return
  end

  schedule(function()
    require('fsouza.plugin')
  end)
end
