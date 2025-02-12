local function hererocks()
  local lua_version = string.gsub(_G._VERSION, "Lua ", "")
  local hererocks_path = _G.cache_dir .. "/hr"
  local share_path = hererocks_path .. "/share/lua/" .. lua_version
  local lib_path = hererocks_path .. "/lib/lua/" .. lua_version

  package.path = table.concat({
    share_path .. "/?.lua",
    share_path .. "/?/init.lua",
    package.path,
  }, ";")

  package.cpath = table.concat({
    lib_path .. "/?.so",
    package.cpath,
  }, ";")
end

local function configure_vendor_packages()
  local vendor_path = vim.fs.joinpath(_G.config_dir, "vendor")
  local vendor_opt_dir = vim.fs.joinpath(vendor_path, "opt")

  vim.o.packpath = vim.o.packpath .. "," .. vendor_path

  for entry, type in vim.fs.dir(vendor_opt_dir) do
    if type == "directory" then
      package.path = table.concat({
        package.path,
        vim.fs.joinpath(vendor_opt_dir, entry, "lua", "?.lua"),
        vim.fs.joinpath(vendor_opt_dir, entry, "lua", "?", "?.lua"),
        vim.fs.joinpath(vendor_opt_dir, entry, "lua", "?", "init.lua"),
      }, ";")
    end
  end
end

local function initial_mappings()
  vim.keymap.set("n", "Q", "")
  vim.keymap.set("n", "<Space>", "")
  vim.g.mapleader = " "
end

local function set_neovim_global_vars()
  local vars = {
    netrw_home = _G.data_dir,
    netrw_banner = 0,
    netrw_liststyle = 3,
    surround_no_insert_mappings = true,
    user_emmet_mode = "i",
    user_emmet_leader_key = "<C-x>",
    wordmotion_extra = {
      "\\([a-f]\\+[0-9]\\+\\([a-f]\\|[0-9]\\)*\\)\\+",
      "\\([0-9]\\+[a-f]\\+\\([0-9]\\|[a-f]\\)*\\)\\+",
      "\\([A-F]\\+[0-9]\\+\\([A-F]\\|[0-9]\\)*\\)\\+",
      "\\([0-9]\\+[A-F]\\+\\([0-9]\\|[A-F]\\)*\\)\\+",
    },
    sexp_filetypes = "clojure,dune,fennel,scheme,lisp,timl",
    sexp_enable_insert_mode_mappings = 0,
    sexp_no_word_maps = 1,
    loaded_python3_provider = 0,
    loaded_ruby_provider = 0,
    loaded_perl_provider = 0,
    loaded_node_provider = 0,
    loaded_matchit = 1,
    loaded_remote_plugins = 1,
    loaded_tarPlugin = 1,
    loaded_2html_plugin = 1,
    loaded_tutor_mode_plugin = 1,
    loaded_zipPlugin = 1,
    no_plugin_maps = 1,
    editorconfig_enable = false,
    matchup_motion_enabled = 0,
    matchup_matchparen_offscreen = vim.empty_dict(),
  }

  for name, value in pairs(vars) do
    vim.g[name] = value
  end
end

local function set_ui_options()
  local options = {
    cursorline = true,
    cursorlineopt = "number",
    showcmd = false,
    laststatus = 0,
    showmode = true,
    ruler = true,
    rulerformat = "%25(%=%{v:lua.require('fsouza.lib.notif').get_notification()}%{v:lua.require('fsouza.lsp.diagnostics').ruler()}   %l,%c%)",
    guicursor = "a:block",
    mouse = "",
    shiftround = true,
    shortmess = "filnxtToOFIc",
    number = true,
    relativenumber = true,
    isfname = "@,48-57,/,.,-,_,+,,,#,$,%,~,=,@-@",
    tabstop = 8,
  }

  for name, value in pairs(options) do
    vim.o[name] = value
  end

  vim.cmd.color("none")
end

local function set_global_options()
  local options = {
    completeopt = "menuone,noinsert,noselect,fuzzy",
    hidden = true,
    hlsearch = false,
    incsearch = true,
    wildmenu = true,
    wildmode = "list:longest",
    backup = false,
    inccommand = "split",
    jumpoptions = "stack",
    scrolloff = 2,
    autoindent = true,
    smartindent = true,
    swapfile = false,
    undofile = true,
    joinspaces = false,
    synmaxcol = 300,
    showmatch = true,
    matchtime = 1,
  }

  for name, value in pairs(options) do
    vim.o[name] = value
  end
end

local function set_global_mappings()
  local rl_bindings = {
    { lhs = "<c-a>", rhs = "<home>" },
    { lhs = "<c-e>", rhs = "<end>" },
    { lhs = "<c-f>", rhs = "<right>" },
    { lhs = "<c-b>", rhs = "<left>" },
    { lhs = "<c-p>", rhs = "<up>" },
    { lhs = "<c-n>", rhs = "<down>" },
    { lhs = "<c-d>", rhs = "<del>" },
    { lhs = "<m-p>", rhs = "<up>" },
    { lhs = "<m-n>", rhs = "<down>" },
    { lhs = "<m-b>", rhs = "<s-left>" },
    { lhs = "<m-f>", rhs = "<s-right>" },
    { lhs = "<m-d>", rhs = "<s-right><c-w>" },
  }

  local rl_insert_mode_bindings = {
    { lhs = "<c-f>", rhs = "<right>" },
    { lhs = "<c-b>", rhs = "<left>" },
  }

  vim.keymap.set({ "x", "v" }, "#", '"my?\\V<C-R>=escape(getreg("m"), "?")<CR><CR>', { remap = false })
  vim.keymap.set({ "x", "v" }, "*", '"my/\\V<C-R>=escape(getreg("m"), "/")<CR><CR>', { remap = false })
  vim.keymap.set({ "x", "v" }, "p", '"_dP', { remap = false })
  vim.keymap.set({ "n" }, "<leader>j", ":cn<CR>", { remap = false })
  vim.keymap.set({ "n" }, "<leader>k", ":cp<CR>", { remap = false })

  for _, binding in ipairs(rl_bindings) do
    vim.keymap.set({ "c", "o" }, binding.lhs, binding.rhs, { remap = false })
  end

  for _, binding in ipairs(rl_insert_mode_bindings) do
    vim.keymap.set("i", binding.lhs, binding.rhs, { remap = false })
  end
end

local function set_global_abbrev()
  local cabbrevs = { W = "w", ["W!"] = "w!", Q = "q", ["Q!"] = "q!", Qa = "qa", ["Qa!"] = "qa!" }

  for lhs, rhs in pairs(cabbrevs) do
    vim.cmd.cnoreabbrev(lhs, rhs)
  end
end

local function override_builtin_functions()
  local orig_uri_to_fname = vim.uri_to_fname

  local function uri_to_fname(uri)
    return vim.fn.fnamemodify(orig_uri_to_fname(uri), ":.")
  end

  vim.uri_to_fname = uri_to_fname
  vim.uri_to_bufnr = function(uri)
    return vim.fn.bufadd(uri_to_fname(uri))
  end

  vim.ui.select = function(...)
    local popup_picker = require("fsouza.lib.popup-picker")
    return popup_picker["ui-select"](...)
  end

  vim.deprecate = function() end

  local patterns = { "message with no corresponding" }
  local orig_notify = vim.notify

  local function notify(msg, level, opts)
    local should_notify = true
    for _, pattern in ipairs(patterns) do
      if string.find(msg, pattern) ~= nil then
        should_notify = false
        break
      end
    end

    if should_notify then
      orig_notify(msg, level, opts)
    end
  end

  vim.notify = notify
end

-- Main initialization
local dotfiles_dir = vim.env.FSOUZA_DOTFILES_DIR or vim.fn.expand("~/.dotfiles")
vim.loader.enable()
_G.dotfiles_dir = dotfiles_dir
_G.dotfiles_cache_dir = vim.env.FSOUZA_DOTFILES_CACHE_DIR or vim.fn.expand("~/.cache/fsouza-dotfiles")
_G.config_dir = dotfiles_dir .. "/nvim"
_G.cache_dir = vim.fn.stdpath("cache")
_G.data_dir = vim.fn.stdpath("data")

hererocks()
configure_vendor_packages()
initial_mappings()
set_global_options()
set_global_mappings()
set_global_abbrev()
override_builtin_functions()
set_ui_options()
set_neovim_global_vars()
