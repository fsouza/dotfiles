(import-macros {: if-nil : mod-invoke} :helpers)

(local non-focusable-handlers {})

(fn popup-callback [err result context ...]
  (let [method context.method
        handler (if-nil (. non-focusable-handlers method)
                        (vim.lsp.with (. vim.lsp.handlers method)
                                      {:focusable false}))]
    (tset non-focusable-handlers method handler)
    (handler err result context ...)))

(fn fzf-location-callback [_ result ctx]
  (when (and result (not (vim.tbl_isempty result)))
    (let [client (vim.lsp.get_client_by_id ctx.client_id)]
      (if (vim.tbl_islist result)
          (if (> (length result) 1)
              (let [items (vim.lsp.util.locations_to_items result
                                                           client.offset_encoding)]
                (mod-invoke :fsouza.plugin.fuzzy :send-items items :Locations))
              (vim.lsp.util.jump_to_location (. result 1)
                                             client.offset_encoding))
          (vim.lsp.util.jump_to_location result client.offset_encoding)))))

(fn register-capability [_ result ctx]
  (when (and result result.registrations)
    (each [_ registration (pairs result.registrations)]
      (when (and (= registration.method :workspace/didChangeWatchedFiles)
                 (?. registration :registerOptions :watchers))
        (mod-invoke :fsouza.lsp.fs-watch :register ctx.client_id
                    registration.registerOptions.watchers))))
  vim.NIL)

(fn unregister-capability [_ result ctx]
  (when (and result result.unregisterations)
    (each [_ unregistration (pairs result.unregisterations)]
      (when (= unregistration.method :workspace/didChangeWatchedFiles)
        (mod-invoke :fsouza.lsp.fs-watch :unregister ctx.client_id))))
  vim.NIL)

{:textDocument/declaration fzf-location-callback
 :textDocument/definition fzf-location-callback
 :textDocument/typeDefinition fzf-location-callback
 :textDocument/implementation fzf-location-callback
 :textDocument/references (fn [err result ...]
                            (let [result (mod-invoke :fsouza.lsp.references
                                                     :filter-references result)]
                              (fzf-location-callback err result ...)))
 :textDocument/documentHighlight (fn [_ result context]
                                   (when (not result)
                                     (lua :return))
                                   (let [bufnr (vim.api.nvim_get_current_buf)
                                         client (vim.lsp.get_client_by_id context.client_id)]
                                     (vim.lsp.util.buf_clear_references bufnr)
                                     (vim.lsp.util.buf_highlight_references bufnr
                                                                            result
                                                                            client.offset_encoding)))
 :textDocument/hover popup-callback
 :textDocument/signatureHelp popup-callback
 :textDocument/publishDiagnostics (fn [...]
                                    (let [buf-diagnostics (require :fsouza.lsp.buf-diagnostic)]
                                      (buf-diagnostics.publish-diagnostics ...)))
 :client/registerCapability register-capability
 :client/unregisterCapability unregister-capability}
