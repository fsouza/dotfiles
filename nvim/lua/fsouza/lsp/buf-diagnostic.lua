local debouncers = {}
local hooks = {}
local filters = {}

local function register_filter(client_name, f)
  filters[client_name] = f
end

local function filter(result, client)
  if result and client then
    local client_filter = filters[client.name] or function() return true end
    local diagnostics = result.diagnostics
    
    if diagnostics and client then
      local filtered_diagnostics = {}
      for _, diagnostic in ipairs(diagnostics) do
        if client_filter(diagnostic) then
          table.insert(filtered_diagnostics, diagnostic)
        end
      end
      result.diagnostics = filtered_diagnostics
    end
  end
  
  return result
end

local function buf_clear_all_diagnostics()
  local all_clients = vim.lsp.get_active_clients()
  for _, client in ipairs(all_clients) do
    vim.diagnostic.hide(vim.lsp.diagnostic.get_namespace(client.id))
  end
end

-- This is a workaround because the default lsp client doesn't let us hook into
-- textDocument/didChange like coc.nvim does.
local function exec_hooks()
  for _, f in ipairs(hooks) do
    f()
  end
end

local function make_handler()
  return function(err, result, context, ...)
    vim.schedule(exec_hooks)
    pcall(vim.diagnostic.reset, context.client_id, context.bufnr)
    
    local client = vim.lsp.get_client_by_id(context.client_id)
    local filtered_result = filter(result, client)
    
    if client then
      vim.lsp.diagnostic.on_publish_diagnostics(err, filtered_result, context, ...)
    end
  end
end

local function make_debounced_handler(bufnr, debouncer_key)
  local interval_ms = vim.b[bufnr].lsp_diagnostic_debouncing_ms or 200
  local debounce = require("fsouza.lib.debounce")
  local handler = debounce.debounce(interval_ms, vim.schedule_wrap(make_handler()))
  
  debouncers[debouncer_key] = handler
  
  vim.api.nvim_buf_attach(bufnr, false, {
    on_detach = function()
      handler.stop()
      debouncers[debouncer_key] = nil
    end
  })
  
  return handler
end

local function publish_diagnostics(err, result, context, ...)
  if result then
    local uri = result.uri
    local bufnr = vim.uri_to_bufnr(uri)
    
    if bufnr then
      context.bufnr = bufnr
      local debouncer_key = string.format("%d/%s", context.client_id, uri)
      local handler = debouncers[debouncer_key] or 
                     make_debounced_handler(bufnr, debouncer_key)
      
      handler.call(err, result, context, ...)
    end
  end
end

local function register_hook(idx, fn)
  hooks[idx] = fn
end

local function unregister_hook(idx)
  hooks[idx] = nil
end

return {
  buf_clear_all_diagnostics = buf_clear_all_diagnostics,
  register_filter = register_filter,
  register_hook = register_hook,
  unregister_hook = unregister_hook,
  publish_diagnostics = publish_diagnostics
}