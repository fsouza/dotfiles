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
  require('fsouza.tablex').foreach(callbacks[bufnr] or {}, function(cb)
    cb(bufnr)
  end)

  callbacks[bufnr] = nil
end

function M.restart()
  local tablex = require('fsouza.tablex')

  local function extract_client_id(client)
    return client.id
  end

  local all_clients = vim.lsp.get_active_clients()
  local original_client_ids = tablex.map(extract_client_id, all_clients)

  local function check_new_clients()
    local current_client_ids = tablex.map(extract_client_id, vim.lsp.get_active_clients())

    for _, client_id in ipairs(current_client_ids) do
      if not vim.tbl_contains(original_client_ids, client_id) then
        return true, #current_client_ids
      end
    end

    return false, #current_client_ids
  end

  vim.lsp.stop_client(all_clients)

  local timer = vim.loop.new_timer()
  timer:start(50, 50, vim.schedule_wrap(function()
    local has_new_clients, total_clients = check_new_clients()
    if has_new_clients then
      timer:stop()
      return
    end

    if total_clients == 0 then
      timer:stop()
      vim.cmd([[silent! edit]])
    end
  end))

  require('fsouza.lsp.buf_diagnostic').buf_clear_all_diagnostics()
  local safe_detach = vim.F.nil_wrap(detach)

  tablex.foreach(api.nvim_list_bufs(), function(bufnr)
    safe_detach(bufnr)
  end)
end

return M
