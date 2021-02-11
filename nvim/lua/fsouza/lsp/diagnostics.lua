local M = {}

local api = vim.api
local lsp = vim.lsp
local vcmd = vim.cmd

local function items_from_diagnostics(bufnr, diagnostics)
  local fname = api.nvim_buf_get_name(bufnr)
  local items = {}
  for _, diagnostic in ipairs(diagnostics) do
    local pos = diagnostic.range.start
    table.insert(items, {
      filename = fname;
      lnum = pos.line + 1;
      col = pos.character + 1;
      text = diagnostic.message;
    })
  end
  return items
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
  local diagnostics = vim.lsp.diagnostic.get(bufnr)
  if not diagnostics then
    return
  end

  local items = items_from_diagnostics(bufnr, diagnostics)
  render_diagnostics(items)
end

function M.list_workspace_diagnostics()
  local all_diagnostics = vim.lsp.diagnostic.get_all()
  local all_items = {}
  for bufnr, diagnostics in pairs(all_diagnostics) do
    local buffer_items = items_from_diagnostics(bufnr, diagnostics)
    for _, item in ipairs(buffer_items) do
      table.insert(all_items, item)
    end
  end
  render_diagnostics(all_items)
end

return M
