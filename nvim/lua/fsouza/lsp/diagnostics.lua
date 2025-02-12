local n_diag_per_buf = {}

local function render_diagnostics(diagnostics)
  local items = vim.diagnostic.toqflist(diagnostics)
  vim.fn.setqflist(items)

  if vim.tbl_isempty(items) then
    vim.cmd.cclose()
  else
    vim.cmd.copen()
    vim.cmd.wincmd("p")
    vim.cmd.cc()
  end
end

local function list_file_diagnostics()
  local bufnr = vim.api.nvim_get_current_buf()
  render_diagnostics(vim.diagnostic.get(bufnr))
end

local function list_workspace_diagnostics()
  render_diagnostics(vim.diagnostic.get())
end

local function on_DiagnosticChanged()
  local acc = {}
  for _, diag in ipairs(vim.diagnostic.get()) do
    local bufnr = diag.bufnr
    local curr = acc[bufnr] or 0
    acc[bufnr] = curr + 1
  end
  n_diag_per_buf = acc
end

local function ruler()
  local bufnr = vim.api.nvim_get_current_buf()
  local count = n_diag_per_buf[bufnr] or 0

  if count == 0 then
    return "    "
  else
    return string.format("D:%02d", count)
  end
end

local function on_attach()
  local augroup = require("fsouza.lib.nvim-helpers").augroup
  augroup("fsouza__lsp_diagnostic", {
    {
      events = { "DiagnosticChanged" },
      targets = { "*" },
      callback = on_DiagnosticChanged,
    },
  })
end

return {
  list_file_diagnostics = list_file_diagnostics,
  list_workspace_diagnostics = list_workspace_diagnostics,
  on_attach = on_attach,
  ruler = ruler,
}
