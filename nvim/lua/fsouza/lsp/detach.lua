local api = vim.api

local M = {}

local callbacks = {}

function M.register(bufnr, cb)
  if not callbacks[bufnr] then
    callbacks[bufnr] = {cb}
  else
    table.insert(callbacks[bufnr], cb)
  end
end

local function detach(bufnr)
  for _, cb in ipairs(callbacks[bufnr] or {}) do
    cb(bufnr)
  end

  callbacks[bufnr] = nil
end

function M.restart()
  vim.lsp.stop_client(vim.lsp.get_active_clients())

  require('fsouza.lsp.buf_diagnostic').buf_clear_all_diagnostics()

  for _, bufnr in ipairs(api.nvim_list_bufs()) do
    detach(bufnr)
  end

  local interval_ms = 50
  local edit = nil
  edit = function()
    local active_clients = vim.lsp.get_active_clients()
    if #active_clients > 0 then
      vim.defer_fn(edit, interval_ms)
      return
    end
    vim.cmd([[edit]])
  end

  vim.defer_fn(edit, interval_ms)
end

return M
