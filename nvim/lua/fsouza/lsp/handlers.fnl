(local non-focusable-handlers {})

(fn popup-callback [err result context ...]
  (let [method context.method
        handler (or (. non-focusable-handlers method)
                    (vim.lsp.with (. vim.lsp.handlers method)
                      {:focusable true}))]
    (tset non-focusable-handlers method handler)
    (let [(_ winid) (handler err result context ...)]
      (when winid
        (let [p (require :fsouza.lib.popup)]
          (p.stylize winid))))))

(fn fzf-location-callback [_ result ctx]
  (when (and result (not (vim.tbl_isempty result)))
    (let [client (vim.lsp.get_client_by_id ctx.client_id)]
      (if (vim.islist result)
          (if (> (length result) 1)
              (let [items (vim.lsp.util.locations_to_items result
                                                           client.offset_encoding)
                    fuzzy (require :fsouza.lib.fuzzy)]
                (fuzzy.send-lsp-items items :Locations))
              (vim.lsp.util.jump_to_location (. result 1)
                                             client.offset_encoding))
          (vim.lsp.util.jump_to_location result client.offset_encoding)))))

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

{:textDocument/declaration fzf-location-callback
 :textDocument/definition fzf-location-callback
 :textDocument/typeDefinition fzf-location-callback
 :textDocument/implementation fzf-location-callback
 :textDocument/references (fn [err result ...]
                            (let [references (require :fsouza.lsp.references)
                                  result (references.filter-references result)]
                              (fzf-location-callback err result ...)))
 :textDocument/documentHighlight (fn [_ result context]
                                   (when result
                                     (let [bufnr (vim.api.nvim_get_current_buf)
                                           client (vim.lsp.get_client_by_id context.client_id)]
                                       (vim.lsp.util.buf_clear_references bufnr)
                                       (vim.lsp.util.buf_highlight_references bufnr
                                                                              result
                                                                              client.offset_encoding))))
 :textDocument/hover popup-callback
 :textDocument/signatureHelp popup-callback
 :textDocument/diagnostic (let [buf-diagnostic (require :fsouza.lsp.buf-diagnostic)]
                            buf-diagnostic.handle-diagnostics)
 :textDocument/publishDiagnostics (let [buf-diagnostic (require :fsouza.lsp.buf-diagnostic)]
                                    buf-diagnostic.publish-diagnostics)
 :client/registerCapability register-capability
 :client/unregisterCapability unregister-capability
 :window/logMessage (let [log-message (require :fsouza.lsp.log-message)]
                      log-message.handle)
 :window/showMessage (let [log-message (require :fsouza.lsp.log-message)]
                       log-message.handle)}
