local api = vim.api

local M = {}

local clients_by_buf = {}

-- returns two tables: one in list-style and the other in map-style. The first
-- is a list of command names, and the second is a map from command name to
-- client instance.
local all_commands = function(bufnr)
  local commands = {}
  local client_for_command = {}

  print(vim.inspect(clients_by_buf[bufnr]))
  for _, client in ipairs(clients_by_buf[bufnr]) do
    for _, command in ipairs(client.server_capabilities.executeCommandProvider.commands) do
      table.insert(commands, command)
      client_for_command[command] = client
    end
  end

  return commands, client_for_command
end

function M.execute_command(bufnr)
  local command_names, command_mapping = all_commands(bufnr)
  if vim.tbl_isempty(command_names) then
    return
  end
  require('lib.popup_picker').open(command_names, function(index)
    local command = command_names[index]
    local client = command_mapping[command]
    if not client then
      return
    end
    client.request('workspace/executeCommand', {command = command})
  end)
end

local buf_attach_if_needed = function(bufnr)
  if clients_by_buf[bufnr] then
    return
  end

  api.nvim_buf_attach(bufnr, false, {
    on_detach = function(_)
      clients_by_buf[bufnr] = nil
    end;
  })
end

function M.on_attach(opts)
  local bufnr = opts.bufnr
  buf_attach_if_needed(bufnr)
  clients_by_buf[bufnr] = clients_by_buf[bufnr] or {}
  table.insert(clients_by_buf[bufnr], opts.client)
end

return M
