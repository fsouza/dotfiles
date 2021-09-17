local M = {}

local api = vim.api
local lsp = vim.lsp
local vcmd = vim.cmd

local function items_from_diagnostics(bufnr, diagnostics)
  local fname = api.nvim_buf_get_name(bufnr)
  return require('fsouza.tablex').map(function(diagnostic)
    local pos = diagnostic.range.start
    return {
      filename = fname;
      lnum = pos.line + 1;
      col = pos.character + 1;
      text = diagnostic.message;
    }
  end, diagnostics)
end

local function render_diagnostics(items)
  lsp.util.set_qflist(items)
  if vim.tbl_isempty(items) then
    vcmd('cclose')
  else
    vcmd('copen')
    vcmd('wincmd p')
    vcmd('cc')
  end
end

function M.list_file_diagnostics()
  local bufnr = api.nvim_get_current_buf()
  local diagnostics = vim.diagnostic.get(bufnr)
  if not diagnostics then
    return
  end

  local items = items_from_diagnostics(bufnr, diagnostics)
  render_diagnostics(items)
end

function M.list_workspace_diagnostics()
  local all_diagnostics = vim.diagnostic.get(nil)
  local all_items = require('fsouza.tablex').flat_map(
                      function(diagnostics, bufnr)
      return items_from_diagnostics(bufnr, diagnostics)
    end, all_diagnostics)
  render_diagnostics(all_items)
end

return M
