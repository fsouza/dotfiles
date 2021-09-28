local vfn = vim.fn

local M = {}

local helpers = require('fsouza.lib.nvim_helpers')

local function should_qf(selected)
  if #selected <= 2 then
    return false
  end

  return require('fsouza.tablex').exists(selected, function(sel)
    if string.match(sel, '^.+:%d+:%d+:') then
      return true
    else
      return false
    end
  end)
end

local function edit_or_qf(selected)
  local actions = require('fzf-lua.actions')
  if should_qf(selected) then
    actions.file_sel_to_qf(selected)
    vim.cmd('cc')
  else
    actions.file_edit(selected, {})
  end
end

local function file_actions()
  local actions = require('fzf-lua.actions')
  return {
    ['default'] = edit_or_qf;
    ['ctrl-s'] = actions.file_split;
    ['ctrl-v'] = actions.file_vsplit;
    ['ctrl-t'] = actions.file_tabedit;
    ['ctrl-q'] = actions.file_sel_to_qf;
  }
end

local fzf_lua = helpers.once(function()
  vim.cmd('packadd nvim-fzf')
  local actions = file_actions()

  local _fzf_lua = require('fzf-lua')
  _fzf_lua.setup({
    fzf_args = vim.env.FZF_DEFAULT_OPTS;
    fzf_layout = 'default';
    fzf_binds = {
      'alt-a:toggle-all';
      'ctrl-l:clear-query';
      'ctrl-d:preview-half-page-down';
      'ctrl-u:preview-half-page-up';
      'ctrl-h:toggle-preview';
    };
    buffers = {file_icons = false; git_icons = false};
    files = {file_icons = false; git_icons = false; actions = actions};
    git = {files = {file_icons = false; git_icons = false; actions = actions}};
    grep = {file_icons = false; git_icons = false; actions = actions};
    oldfiles = {file_icons = false; git_icons = false; actions = actions};
    lsp = {file_icons = false; git_icons = false; actions = actions};
    winopts = {win_height = 0.75; win_width = 0.90};
    previewers = {
      builtin = {
        keymap = {
          toggle_hide = '<c-h>';
          toggle_full = '<c-o>';
          page_up = '<c-u>';
          page_down = '<c-d>';
          page_reset = '<c-r>';
        };
      };
    };
  })

  return _fzf_lua
end)

function M.find_files(dir)
  fzf_lua().files({cwd = dir})
end

do
  local rg_opts =
    '--column -n --hidden --no-heading --color=always -S --glob \'!.git\' --glob \'!.hg\''

  function M.grep(search)
    search = search or vfn.input('rg：')
    if search ~= '' then
      fzf_lua().grep({
        search = search;
        raw_cmd = string.format('rg %s -- %s', rg_opts, vfn.shellescape(search));
      })
    end
  end

  function M.grep_visual()
    fzf_lua().grep_visual({rg_opts = rg_opts})
  end
end

function M.send_items(items, prompt)
  prompt = prompt .. '：'

  -- import this early to make sure fzf-lua is properly configured.
  local fzf_files = fzf_lua().fzf_files

  local config = require('fzf-lua.config')
  local core = require('fzf-lua.core')
  local opts = config.normalize_opts({prompt = prompt; cwd = vfn.getcwd()}, config.globals.lsp)
  opts.fzf_fn = require('fsouza.tablex').map(function(item)
    item = core.make_entry_lcol(opts, item)
    return core.make_entry_file(opts, item)
  end, items)
  opts = core.set_fzf_line_args(opts)
  fzf_files(opts)
end

return setmetatable(M, {
  __index = function(table, key)
    local value = fzf_lua()[key]
    rawset(table, key, value)
    return value
  end;
})
