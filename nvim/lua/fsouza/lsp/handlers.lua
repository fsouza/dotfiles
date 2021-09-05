local M = {}

local api = vim.api
local lsp = vim.lsp

local non_focusable_handlers = {}

local function popup_callback(err, result, context, ...)
  local method = context.method
  if non_focusable_handlers[method] == nil then
    non_focusable_handlers[method] = vim.lsp.with(vim.lsp.handlers[method], {focusable = false})
  end
  non_focusable_handlers[method](err, result, context, ...)
  for _, winid in ipairs(api.nvim_list_wins()) do
    if pcall(api.nvim_win_get_var, winid, method) then
      require('fsouza.color').set_popup_winid(winid)
    end
  end
end

local function fzf_location_callback(_, result)
  if result == nil or vim.tbl_isempty(result) then
    return nil
  end

  if vim.tbl_islist(result) then
    if #result > 1 then
      local items = lsp.util.locations_to_items(result)
      require('fsouza.lsp.fzf').send(items, 'Locations')
    else
      lsp.util.jump_to_location(result[1])
    end
  else
    lsp.util.jump_to_location(result)
  end
end

M['textDocument/declaration'] = fzf_location_callback
M['textDocument/definition'] = fzf_location_callback
M['textDocument/typeDefinition'] = fzf_location_callback
M['textDocument/implementation'] = fzf_location_callback

M['textDocument/references'] = function(err, result, ...)
  if vim.tbl_islist(result) then
    local lineno = api.nvim_win_get_cursor(0)[1] - 1
    local new_result = {}
    for _, v in ipairs(result) do
      if v.range.start.line ~= lineno then
        table.insert(new_result, v)
      end
    end
    result = new_result
  end
  fzf_location_callback(err, result, ...)
end

M['textDocument/documentHighlight'] = function(_, result)
  if not result then
    return
  end
  local bufnr = api.nvim_get_current_buf()
  lsp.util.buf_clear_references(bufnr)
  lsp.util.buf_highlight_references(bufnr, result)
end

M['textDocument/hover'] = popup_callback

M['textDocument/signatureHelp'] = popup_callback

M['textDocument/publishDiagnostics'] = function(...)
  require('fsouza.lsp.buf_diagnostic').publish_diagnostics(...)
end

return M
