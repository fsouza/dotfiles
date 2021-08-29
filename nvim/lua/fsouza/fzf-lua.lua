local _fzf_lua = nil

local function should_qf(selected)
  if #selected <= 2 then
    return false
  end

  for _, sel in ipairs(selected) do
    if string.match(sel, '^.+:%d+:%d+:') then
      return true
    end
  end

  return false
end

local function edit_or_qf(selected)
  local actions = require('fzf-lua.actions')
  if should_qf(selected) then
    actions.file_sel_to_qf(selected)
    vim.cmd('cc')
  else
    actions.file_edit(selected)
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

local function fzf_lua()
  if _fzf_lua == nil then
    local actions = file_actions()

    _fzf_lua = require('fzf-lua')
    _fzf_lua.setup({
      fzf_args = vim.env.FZF_DEFAULT_OPTS;
      fzf_layout = 'default';
      fzf_binds = {
        'ctrl-h:toggle-preview';
        'ctrl-f:page-down';
        'ctrl-b:page-up';
        'ctrl-a:toggle-all';
        'ctrl-l:clear-query';
      };
      buffers = {file_icons = false; git_icons = false};
      files = {file_icons = false; git_icons = false; actions = actions};
      git = {files = {file_icons = false; git_icons = false; actions = actions}};
      grep = {file_icons = false; git_icons = false; actions = actions};
      oldfiles = {file_icons = false; git_icons = false; actions = actions};
      lsp = {file_icons = false; git_icons = false; actions = actions};
      winopts = {
        win_height = 0.65;
        win_width = 0.90;
        window_on_create = function()
          vim.wo.cursorlineopt = 'both'
        end;
      };
      previewers = {
        builtin = {
          keymap = {
            toggle_hide = '<c-h>';
            page_up = '<c-u>';
            page_down = '<c-d>';
            page_reset = '<c-r>';
          };
        };
      };
    })
  end
  return _fzf_lua
end

return setmetatable({}, {
  __index = function(table, key)
    local value = fzf_lua()[key]
    rawset(table, key, value)
    return value
  end;
})
