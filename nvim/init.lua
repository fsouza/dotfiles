local vcmd = vim.cmd
local vfn = vim.fn

local cache_dir = vfn.stdpath('cache')
local data_dir = vfn.stdpath('data')

_G.prequire = vim.F.nil_wrap(require)

local function initial_mappings()
  require('fsouza.lib.nvim_helpers').create_mappings({
    n = {{lhs = 'Q'; rhs = ''}; {lhs = '<Space>'; rhs = ''}; {lhs = '<c-t>'; rhs = ''}};
  })
  vim.g.mapleader = ' '
end

local function hererocks()
  local lua_version = string.gsub(_VERSION, 'Lua ', '')
  local hererocks_path = cache_dir .. '/hr'
  local share_path = hererocks_path .. '/share/lua/' .. lua_version
  local lib_path = hererocks_path .. '/lib/lua/' .. lua_version
  package.path = share_path .. '/?.lua' .. ';' .. share_path .. '/?/init.lua;' .. package.path
  package.cpath = package.cpath .. ';' .. lib_path .. '/?.so'
end

local function add_paqs_opt_to_path()
  local path = require('pl.path')

  local packed = require('fsouza.packed')
  local opt_dir = path.join(packed.paq_dir, 'opt')

  require('fsouza.tablex').foreach(packed.paqs, function(paq)
    if paq.opt and paq.as then
      local paq_dir = path.join(opt_dir, paq.as)
      package.path = package.path .. ';' .. path.join(paq_dir, 'lua', '?.lua') .. ';' ..
                       path.join(paq_dir, 'lua', '?', '?.lua') .. ';' ..
                       path.join(paq_dir, 'lua', '?', 'init.lua')
    end
  end)
end

local function global_vars()
  vim.g.netrw_home = data_dir
  vim.g.netrw_banner = 0
  vim.g.netrw_liststyle = 3
  vim.g.surround_no_insert_mappings = true
  vim.g.user_emmet_mode = 'i'
  vim.g.user_emmet_leader_key = [[<C-x>]]
  vim.g.wordmotion_extra = {
    [=[\([a-f]\+[0-9]\+\([a-f]\|[0-9]\)*\)\+]=];
    [=[\([0-9]\+[a-f]\+\([0-9]\|[a-f]\)*\)\+]=];
    [=[\([A-F]\+[0-9]\+\([A-F]\|[0-9]\)*\)\+]=];
    [=[\([0-9]\+[A-F]\+\([0-9]\|[A-F]\)*\)\+]=];
  }
  vim.g.zig_fmt_autosave = 0
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
  vim.o.lazyredraw = true
  require('fsouza.color').enable()
end

local function global_options()
  vim.o.completeopt = 'menuone,noinsert,noselect'
  vim.o.hidden = true
  vim.o.hlsearch = false
  vim.o.incsearch = true
  vim.o.wildmenu = true
  vim.o.wildmode = 'list:longest'
  vim.o.backup = false
  vim.o.inccommand = 'nosplit'
  vim.o.jumpoptions = 'stack'
  vim.o.scrolloff = 2
  vim.o.autoindent = true
  vim.o.smartindent = true
  vim.o.swapfile = false
  vim.o.undofile = true
  vim.o.joinspaces = false
  vim.o.synmaxcol = 300
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

  local rl_insert_mode_bindings = {
    {lhs = '<c-f>'; rhs = '<right>'; opts = {noremap = true}};
    {lhs = '<c-b>'; rhs = '<left>'; opts = {noremap = true}};
    {lhs = '<c-d>'; rhs = '<del>'; opts = {noremap = true}};
  }

  local maps = {c = rl_bindings; o = rl_bindings; i = rl_insert_mode_bindings}

  require('fsouza.lib.nvim_helpers').create_mappings(maps)
end

do
  hererocks()
  add_paqs_opt_to_path()

  if not vim.env.BOOTSTRAP_PAQ then
    require('impatient').enable_profile()
  end

  local schedule = vim.schedule
  initial_mappings()

  schedule(function()
    global_options()
    global_mappings()
  end)

  ui_options()
  folding()
  global_vars()

  if vim.env.BOOTSTRAP_PAQ then
    require('fsouza.packed').setup()
    return
  end

  schedule(function()
    require('fsouza.plugin')
  end)
end
