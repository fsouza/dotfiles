local virtual_cwd = nil

local function should_qf(selected)
  local n_selected = #selected
  local it = vim.iter(selected)

  if #selected <= 1 then
    return false
  else
    return it:any(function(item)
      return string.match(item, "^.+:%d+:%d+:") ~= nil
    end)
  end
end

local function edit_or_qf(edit, selected, opts)
  if should_qf(selected) then
    local actions = require("fzf-lua.actions")
    actions.file_sel_to_qf(selected, opts)
    vim.cmd.cc()
  else
    edit(selected, opts)
  end
end

local function edit(command, selected, opts)
  local fzf_path = require("fzf-lua.path")

  for _, sel in ipairs(selected) do
    local file_info = fzf_path.entry_to_file(sel, opts)
    local path = file_info.path
    local line = file_info.line or 1
    local col = file_info.col or 1

    line = math.max(line, 1)
    col = math.max(col, 1)

    path = vim.fs.relpath(vim.uv.cwd(), path) or vim.fs.abspath(path)
    vim.api.nvim_cmd({
      cmd = command,
      args = { path },
      bang = true,
      mods = { silent = true },
    }, {})

    if line ~= 1 or col ~= 1 then
      vim.api.nvim_win_set_cursor(0, { line, col - 1 })
      vim.api.nvim_feedkeys("zz", "n", false)
    end
  end
end

local function file_actions()
  local actions = require("fzf-lua.actions")
  return {
    enter = function(selected, opts)
      edit_or_qf(function(sel, o)
        edit("edit", sel, o)
      end, selected, opts)
    end,
    ["ctrl-s"] = function(selected, opts)
      edit_or_qf(function(sel, o)
        edit("split", sel, o)
      end, selected, opts)
    end,
    ["ctrl-x"] = function(selected, opts)
      edit_or_qf(function(sel, o)
        edit("split", sel, o)
      end, selected, opts)
    end,
    ["ctrl-v"] = function(selected, opts)
      edit_or_qf(function(sel, o)
        edit("vsplit", sel, o)
      end, selected, opts)
    end,
    ["ctrl-t"] = function(selected, opts)
      edit_or_qf(function(sel, o)
        edit("tabedit", sel, o)
      end, selected, opts)
    end,
    ["alt-q"] = actions.file_sel_to_qf,
    ["ctrl-q"] = actions.file_sel_to_qf,
  }
end

local function settagstack()
  local lnum, col = unpack(vim.api.nvim_win_get_cursor(0))
  col = col + 1
  vim.fn.settagstack(vim.api.nvim_get_current_win(), {
    items = {
      {
        tagname = vim.fn.expand("<cword>"),
        from = { vim.api.nvim_get_current_buf(), lnum, col, 0 },
      },
    },
  }, "a")
end

local function save_stack_and_edit(selected, opts)
  settagstack()
  edit("edit", selected, opts)
end

local function lsp_actions()
  local actions = file_actions()
  actions.enter = function(selected, opts)
    edit_or_qf(save_stack_and_edit, selected, opts)
  end
  return actions
end

local fzf_lua = (function()
  local once = require("fsouza.lib.nvim-helpers").once
  return once(function()
    vim.cmd.packadd("nvim-fzf")
    local actions = file_actions()
    local fzf_lua_mod = require("fzf-lua")
    local f_config = require("fzf-lua.config")
    local previewer = "builtin"

    fzf_lua_mod.setup({
      fzf_args = vim.env.FZF_DEFAULT_OPTS,
      previewers = {
        builtin = { syntax = false, limit_b = 1024 * 1024 },
        git_diff = {
          pager = "",
          cmd_deleted = "git diff HEAD --",
          cmd_modified = "git diff HEAD",
          cmd_untracked = "git diff --no-index /dev/null",
        },
      },
      buffers = { file_icons = false, git_icons = false, color_icons = false },
      files = {
        previewer = previewer,
        file_icons = false,
        git_icons = false,
        color_icons = false,
        actions = actions,
        hidden = true,
      },
      git = {
        files = {
          file_icons = false,
          git_icons = false,
          color_icons = false,
          actions = actions,
        },
      },
      grep = {
        previewer = previewer,
        file_icons = false,
        git_icons = false,
        color_icons = false,
        actions = actions,
      },
      oldfiles = {
        previewer = previewer,
        file_icons = false,
        git_icons = false,
        color_icons = false,
        actions = actions,
      },
      lsp = {
        file_icons = false,
        git_icons = false,
        color_icons = false,
        actions = lsp_actions(),
      },
      winopts = {
        height = 0.85,
        width = 0.9,
        hls = {
          header_bind = "Black",
          header_text = "Black",
          buf_name = "Black",
          buf_nr = "Black",
          buf_linenr = "Black",
          buf_flag_cur = "Black",
          buf_flag_alt = "Black",
          tab_title = "Black",
          tab_marker = "Black",
        },
      },
      keymap = {
        builtin = {
          ["<c-h>"] = "toggle-preview",
          ["<c-u>"] = "preview-page-up",
          ["<c-d>"] = "preview-page-down",
          ["<c-r>"] = "preview-page-reset",
        },
        fzf = {
          ["alt-a"] = "toggle-all",
          ["ctrl-l"] = "clear-query",
          ["ctrl-d"] = "preview-page-down",
          ["ctrl-u"] = "preview-page-up",
          ["ctrl-h"] = "toggle-preview",
        },
      },
    })

    vim.cmd.color("none")
    f_config.globals.keymap.fzf["ctrl-f"] = nil
    f_config.globals.keymap.fzf["ctrl-b"] = nil
    return fzf_lua_mod
  end)
end)()

local function send_lsp_items(items, title)
  title = " " .. title .. " "
  local fzf_lua_mod = fzf_lua()
  local config = require("fzf-lua.config")
  local core = require("fzf-lua.core")
  local make_entry = require("fzf-lua.make_entry")

  local opts = config.normalize_opts({ winopts = { title = title }, cwd = virtual_cwd }, config.globals.lsp)

  local contents = {}
  for _, item in ipairs(items) do
    if virtual_cwd then
      item.filename = vim.fs.abspath(item.filename)
    end

    local formatted_item = make_entry.lcol(item, {
      cwd = virtual_cwd,
      _cached_hls = { "path_colnr", "path_linenr" },
      hls = {
        path_linenr = "FzfLuaPathLineNr",
        path_colnr = "FzfLuaPathColNr",
      },
    })

    table.insert(contents, make_entry.file(formatted_item, { cwd = virtual_cwd }))
  end

  core.fzf_exec(contents, opts)
end

local function go_to_item(item)
  settagstack()
  local bufnr = item.bufnr or vim.fn.bufadd(item.filename)
  vim.bo[bufnr].buflisted = true
  vim.api.nvim_win_set_buf(0, bufnr)
  vim.api.nvim_win_set_cursor(0, { item.lnum, item.col - 1 })
end

local function lsp_on_list(result)
  if #result.items == 1 then
    go_to_item(result.items[1])
  else
    send_lsp_items(result.items, result.title)
  end
end

local function send_items(items_or_fzf_cb, title, opts)
  local cb = opts and opts.cb
  local use_lsp_actions = opts and opts.use_lsp_actions
  local enable_preview = opts and opts.enable_preview

  local actions = cb and { enter = cb } or (use_lsp_actions and lsp_actions() or file_actions())

  local function send_to_fzf()
    title = " " .. title .. " "
    local fzf_lua_mod = fzf_lua()
    local config = require("fzf-lua.config")
    local core = require("fzf-lua.core")

    local fzf_opts = config.normalize_opts({ winopts = { title = title }, actions = actions }, config.globals.lsp)

    fzf_opts.fzf_opts["--multi"] = false
    if not enable_preview then
      fzf_opts.previewer = nil
    end

    core.fzf_exec(items_or_fzf_cb, fzf_opts)
  end

  if type(items_or_fzf_cb) == "function" then
    send_to_fzf()
  elseif type(items_or_fzf_cb) == "table" then
    if #items_or_fzf_cb == 0 then
      -- Do nothing
    elseif #items_or_fzf_cb == 1 then
      actions.enter(items_or_fzf_cb[1])
    else
      send_to_fzf()
    end
  end
end

local function grep(rg_opts, search, extra_opts, cwd)
  search = search or vim.fn.input("rg：")
  extra_opts = extra_opts or ""
  local fzf_lua_mod = fzf_lua()

  if search ~= "" then
    fzf_lua_mod.grep({
      search = search,
      cwd = cwd or virtual_cwd,
      raw_cmd = string.format("rg %s %s -- %s", rg_opts, extra_opts, vim.fn.shellescape(search)),
    })
  end
end

local function grep_visual(rg_opts, ...)
  local nvim_helpers = require("fsouza.lib.nvim-helpers")
  local search = nvim_helpers.get_visual_selection_contents()[1]
  grep(rg_opts, search, ...)
end

local function live_grep(rg_opts, opts)
  opts = opts or {}
  local fzf_lua_mod = fzf_lua()

  opts.rg_opts = rg_opts
  opts.multiprocess = true
  opts.cwd = opts.cwd or virtual_cwd

  fzf_lua_mod.live_grep_native(opts)
end

local function grep_last(rg_opts, cwd)
  local fzf_lua_mod = fzf_lua()
  fzf_lua_mod.grep_last({ rg_opts = rg_opts, cwd = cwd or virtual_cwd })
end

local function files(opts)
  opts = opts or {}
  opts.cwd = opts.cwd or virtual_cwd
  local fzf_lua_mod = fzf_lua()
  fzf_lua_mod.files(opts)
end

local function handle_repo(run_fzf, cd, selected)
  if #selected == 1 then
    local sel = selected[1]
    sel = vim.fs.abspath(sel)

    if cd then
      vim.api.nvim_set_current_dir(sel)
    end

    if run_fzf then
      files({ cwd = sel })
    end
  end
end

local function git_repos(cwd, cd, run_fzf)
  run_fzf = run_fzf ~= nil and run_fzf or true
  cd = cd ~= nil and cd or true
  local title = " Git repos "
  cwd = cwd or virtual_cwd

  local fzf_lua_mod = fzf_lua()
  local config = require("fzf-lua.config")
  local core = require("fzf-lua.core")

  local opts = config.normalize_opts({
    winopts = { title = title },
    cwd = cwd,
    actions = {
      enter = function(sel)
        handle_repo(run_fzf, cd, sel)
      end,
    },
  }, config.globals.files)

  local contents = core.mt_cmd_wrapper({
    cmd = "fd --hidden --type d --exec dirname {} ';' -- '^.git$'",
  })

  opts = core.set_fzf_field_index(opts)
  opts.fzf_opts["--multi"] = false
  opts.previewer = nil

  core.fzf_exec(contents, opts)
end

local function git_files(opts)
  opts = opts or {}
  local fzf_lua_mod = fzf_lua()
  opts.cwd = opts.cwd or virtual_cwd or vim.uv.cwd()
  fzf_lua_mod.git_files(opts)
end

local function set_virtual_cwd_impl(cwd)
  virtual_cwd = vim.fs.abspath(cwd)
end

local function pick_cwd()
  local fzf_lua_mod = fzf_lua()
  local config = require("fzf-lua.config")
  local core = require("fzf-lua.core")

  local opts = config.normalize_opts({
    actions = {
      enter = function(sel)
        set_virtual_cwd_impl(sel[1])
      end,
    },
  }, config.globals.files)

  local contents = core.mt_cmd_wrapper({ cmd = "fd --type d" })
  opts = core.set_fzf_field_index(opts)
  opts.fzf_opts["--multi"] = false
  opts.previewer = nil

  core.fzf_exec(contents, opts)
end

local function set_virtual_cwd(cwd)
  if cwd == nil then
    pick_cwd()
  else
    set_virtual_cwd_impl(cwd)
  end
end

local function unset_virtual_cwd()
  virtual_cwd = nil
end

local function get_virtual_cwd()
  return virtual_cwd
end

local rg_opts =
  "--column -n --hidden --no-heading --color=always --colors 'match:fg:0x99,0x00,0x00' --colors line:none --colors path:none --colors column:none -S --glob '!.git' --glob '!.hg' --glob '!*.ipynb'"

local mod = {
  files = files,
  git_files = git_files,
  live_grep = function(...)
    return live_grep(rg_opts, ...)
  end,
  grep = function(...)
    return grep(rg_opts, ...)
  end,
  grep_last = function(...)
    return grep_last(rg_opts, ...)
  end,
  grep_visual = function(...)
    return grep_visual(rg_opts, ...)
  end,
  set_virtual_cwd = set_virtual_cwd,
  unset_virtual_cwd = unset_virtual_cwd,
  get_virtual_cwd = get_virtual_cwd,
  git_repos = git_repos,
  lsp_on_list = lsp_on_list,
  send_items = send_items,
}

return setmetatable(mod, {
  __index = function(table, key)
    local fzf_lua_mod = fzf_lua()
    local value = fzf_lua_mod[key]
    rawset(table, key, value)
    return value
  end,
})
