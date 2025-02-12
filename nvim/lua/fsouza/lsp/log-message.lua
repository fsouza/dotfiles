local log_buffers = {}

local function setup_buffer(client_name)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, "lsp-logs-" .. client_name)
  log_buffers[client_name] = bufnr
  return bufnr
end

local function get_buffer(client_id)
  local client = vim.lsp.get_client_by_id(client_id)
  if client then
    return log_buffers[client.name] or setup_buffer(client.name)
  end
  return nil
end

local function handle(err, result, ctx)
  local client_id = ctx.client_id
  local bufnr = get_buffer(client_id)
  
  if bufnr then
    vim.api.nvim_buf_set_lines(
      bufnr, 
      -1, 
      -1, 
      false,
      vim.split(result.message, "\n", {plain = true})
    )
  end
end

local function show_logs_impl(client_name)
  local bufnr = log_buffers[client_name]
  if bufnr then
    vim.api.nvim_set_current_buf(bufnr)
  end
end

local function find_client()
  local client_names = {}
  for _, client in ipairs(vim.lsp.get_active_clients()) do
    table.insert(client_names, client.name)
  end
  
  local fuzzy = require("fsouza.lib.fuzzy")
  fuzzy.send_items(client_names, "LSP Client", {
    cb = function(selected)
      local client_name = selected[1]
      vim.schedule(function() show_logs_impl(client_name) end)
    end
  })
end

local function show_logs(client_name)
  if client_name then
    show_logs_impl(client_name)
  else
    find_client()
  end
end

local function clean_logs(client_name)
  local bufnr = log_buffers[client_name]
  if bufnr then
    vim.api.nvim_buf_delete(bufnr, {force = true})
    log_buffers[client_name] = nil
  end
end

return {
  handle = handle,
  show_logs = show_logs,
  clean_logs = clean_logs
}