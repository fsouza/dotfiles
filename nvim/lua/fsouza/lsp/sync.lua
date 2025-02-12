local function read_buffer(bufnr)
  local lines = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, true), "\n")
  
  if vim.bo[bufnr].eol then
    return lines .. "\n"
  else
    return lines
  end
end

local function notify_clients(bufnr)
  local uri = vim.uri_from_bufnr(bufnr)
  local params = {
    textDocument = {
      uri = uri,
      version = vim.api.nvim_buf_get_changedtick(bufnr)
    },
    contentChanges = {
      {text = read_buffer(bufnr)}
    }
  }
  
  for _, client in pairs(vim.lsp.get_active_clients({bufnr = bufnr})) do
    client:notify("textDocument/didChange", params)
  end
end

local function sync_all_buffers()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    notify_clients(bufnr)
  end
end

return {
  notify_clients = notify_clients,
  sync_all_buffers = sync_all_buffers
}