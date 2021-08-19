local M = {}

local api = vim.api
local lsp = vim.lsp

local function popup_callback(err, method, ...)
  vim.lsp.handlers[method](err, method, ...)
  for _, winid in ipairs(api.nvim_list_wins()) do
    if pcall(api.nvim_win_get_var, winid, method) then
      require('fsouza.color').set_popup_winid(winid)
    end
  end
end

M['textDocument/documentHighlight'] = function(_, _, result, _)
  if not result then
    return
  end
  local bufnr = api.nvim_get_current_buf()
  lsp.util.buf_clear_references(bufnr)
  lsp.util.buf_highlight_references(bufnr, result)
end

M['textDocument/codeAction'] = function(_, _, actions)
  if not actions or vim.tbl_isempty(actions) then
    return
  end
  require('fsouza.lsp.code_action').handle_actions(actions)
end

M['textDocument/hover'] = popup_callback

M['textDocument/signatureHelp'] = popup_callback

M['textDocument/publishDiagnostics'] = function(err, method, result, client_id)
  require('fsouza.lsp.buf_diagnostic').publish_diagnostics(err, method, result, client_id)
end

return M
