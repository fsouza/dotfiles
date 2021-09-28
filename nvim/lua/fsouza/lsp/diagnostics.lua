local M = {}

local api = vim.api
local lsp = vim.lsp
local vcmd = vim.cmd

local function render_diagnostics(items)
  lsp.util.set_qflist(items)
  if vim.tbl_isempty(items) then
    vcmd("cclose")
  else
    vcmd("copen")
    vcmd("wincmd p")
    vcmd("cc")
  end
end

function M.list_file_diagnostics()
  local bufnr = api.nvim_get_current_buf()
  render_diagnostics(vim.diagnostic.toqflist(vim.diagnostic.get(bufnr)))
end

function M.list_workspace_diagnostics()
  local diagnostics = vim.diagnostic.get(nil)
  render_diagnostics(vim.diagnostic.toqflist(diagnostics))
end

return M
