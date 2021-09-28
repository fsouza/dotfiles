local api = vim.api
local vfn = vim.fn
local buf = vim.lsp.buf

local util = vim.lsp.util

local M = {}

local function handle_actions(actions)
  if not actions or vim.tbl_isempty(actions) then
    return
  end

  local lines = require('fsouza.tablex').map(function(action)
    return action.title
  end, actions)

  local function handle_selection(index)
    local action_chosen = actions[index]
    if action_chosen.edit or type(action_chosen.command) == 'table' then
      if action_chosen.edit then
        util.apply_workspace_edit(action_chosen.edit)
      end
      if type(action_chosen.command) == 'table' then
        buf.execute_command(action_chosen.command)
      end
    else
      buf.execute_command(action_chosen)
    end
  end

  require('fsouza.lib.popup_picker').open(lines, handle_selection)
end

local function code_action_for_buf()
  local bufnr = api.nvim_get_current_buf()
  vim.lsp.buf.range_code_action({diagnostics = vim.diagnostic.get(bufnr)}, {1; 1},
                                {api.nvim_buf_line_count(0); 2147483647})
end

local function code_action_for_line(cb)
  local lnum, _ = unpack(api.nvim_win_get_cursor(0))
  local context = {diagnostics = vim.diagnostic.get(0, {lnum = lnum - 1})}
  local params = util.make_range_params()
  params.context = context
  vim.lsp.buf_request(0, 'textDocument/codeAction', params, cb)
end

function M.code_action()
  vim.lsp.handlers['textDocument/codeAction'] = function(_, actions)
    handle_actions(actions)
  end

  code_action_for_line(function(_, actions)
    if not actions or vim.tbl_isempty(actions) then
      return code_action_for_buf(function(_, buf_actions)
        handle_actions(buf_actions)
      end)
    end

    handle_actions(actions)
  end)
end

function M.visual_code_action()
  if vfn.visualmode() == '' then
    return
  end
  api.nvim_input('<esc>')

  local start_pos = vfn.getpos('\'<')
  local end_pos = vfn.getpos('\'>')

  vim.lsp.handlers['textDocument/codeAction'] = function(_, actions)
    handle_actions(actions)
  end

  vim.lsp.buf.range_code_action(nil, {start_pos[2]; start_pos[3]}, {end_pos[2]; end_pos[3]})
end

return M
