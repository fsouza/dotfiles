local non_focusable_handlers = {}

local function register_capability(_, result, ctx)
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  local bufnr = vim.api.nvim_get_current_buf()
  local register_method = require("fsouza.lsp").register_method
  local fs_watch = require("fsouza.lsp.fs-watch")
  
  if client and result and result.registrations then
    client.dynamic_capabilities:register(result.registrations)
    
    for _, registration in pairs(result.registrations) do
      register_method(registration.method, client, bufnr)
      
      if registration.method == "workspace/didChangeWatchedFiles" and
         registration.registerOptions and
         registration.registerOptions.watchers and
         registration.id then
        
        fs_watch.register(
          ctx.client_id,
          registration.id,
          registration.registerOptions.watchers
        )
      end
    end
  end
  
  return vim.NIL
end

local function unregister_capability(_, result, ctx)
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  local fs_watch = require("fsouza.lsp.fs-watch")
  
  if client and result and result.unregistrations then
    client.dynamic_capabilities:unregister(result.unregisterations)
    
    for _, unregistration in pairs(result.unregisterations) do
      if unregistration.method == "workspace/didChangeWatchedFiles" then
        fs_watch.unregister(unregistration.id, ctx.client_id)
      end
    end
  end
  
  return vim.NIL
end

return {
  ["textDocument/diagnostic"] = vim.lsp.diagnostic.on_diagnostic,
  ["textDocument/publishDiagnostics"] = require("fsouza.lsp.buf-diagnostic").publish_diagnostics,
  ["client/registerCapability"] = register_capability,
  ["client/unregisterCapability"] = unregister_capability,
  ["window/logMessage"] = require("fsouza.lsp.log-message").handle,
  ["window/showMessage"] = require("fsouza.lsp.log-message").handle
}