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
  local function extract_client_id(client)
    return client.id
  end

  local all_clients = vim.lsp.get_active_clients()
  local original_client_ids = vim.tbl_map(extract_client_id, all_clients)

  local function check_new_clients()
    local current_client_ids = vim.tbl_map(extract_client_id, vim.lsp.get_active_clients())

    for _, client_id in ipairs(current_client_ids) do
      if not vim.tbl_contains(original_client_ids, client_id) then
        return true, #current_client_ids
      end
    end

    return false, #current_client_ids
  end

  vim.lsp.stop_client(all_clients)

  local interval_ms = 50
  local edit = nil
  edit = function()
    local has_new_clients, total_clients = check_new_clients()
    if has_new_clients then
      return
    end

    if total_clients > 0 then
      vim.defer_fn(edit, interval_ms)
      return
    end

    vim.cmd([[edit]])
  end

  vim.defer_fn(edit, interval_ms)

  require('fsouza.lsp.buf_diagnostic').buf_clear_all_diagnostics()
  for _, bufnr in ipairs(api.nvim_list_bufs()) do
    detach(bufnr)
  end
end

return M
