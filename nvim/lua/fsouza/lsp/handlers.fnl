(local non-focusable-handlers {})

(fn register-capability [_ result ctx]
  (let [client (vim.lsp.get_client_by_id ctx.client_id)
        bufnr (vim.api.nvim_get_current_buf)
        {: register-method} (require :fsouza.lsp)
        fs-watch (require :fsouza.lsp.fs-watch)]
    (when (and client result result.registrations)
      (client.dynamic_capabilities:register result.registrations)
      (each [_ registration (pairs result.registrations)]
        (register-method registration.method client bufnr)
        (when (and (= registration.method :workspace/didChangeWatchedFiles)
                   (?. registration :registerOptions :watchers)
                   (. registration :id))
          (fs-watch.register ctx.client_id registration.id
                             registration.registerOptions.watchers)))))
  vim.NIL)

(fn unregister-capability [_ result ctx]
  (let [client (vim.lsp.get_client_by_id ctx.client_id)
        fs-watch (require :fsouza.lsp.fs-watch)]
    (when (and client result result.unregistrations)
      (client.dynamic_capabilities:unregister result.unregisterations)
      (each [_ unregistration (pairs result.unregisterations)]
        (when (= unregistration.method :workspace/didChangeWatchedFiles)
          (fs-watch.unregister unregistration.id ctx.client_id)))))
  vim.NIL)

{:textDocument/diagnostic vim.lsp.diagnostic.on_diagnostic
 :textDocument/publishDiagnostics (let [buf-diagnostic (require :fsouza.lsp.buf-diagnostic)]
                                    buf-diagnostic.publish-diagnostics)
 :client/registerCapability register-capability
 :client/unregisterCapability unregister-capability
 :window/logMessage (let [log-message (require :fsouza.lsp.log-message)]
                      log-message.handle)
 :window/showMessage (let [log-message (require :fsouza.lsp.log-message)]
                       log-message.handle)}
