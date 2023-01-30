(import-macros {: mod-invoke} :helpers)

(local non-focusable-handlers {})

(fn popup-callback [err result context ...]
  (let [method context.method
        handler (or (. non-focusable-handlers method)
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
                (mod-invoke :fsouza.lib.fuzzy :send-items items :Locations))
              (vim.lsp.util.jump_to_location (. result 1)
                                             client.offset_encoding))
          (vim.lsp.util.jump_to_location result client.offset_encoding)))))

(fn register-capability [_ result ctx]
  (when (and result result.registrations)
    (each [_ registration (pairs result.registrations)]
      (when (and (= registration.method :workspace/didChangeWatchedFiles)
                 (?. registration :registerOptions :watchers)
                 (. registration :id))
        (mod-invoke :fsouza.lsp.fs-watch :register ctx.client_id
                    registration.id registration.registerOptions.watchers))))
  vim.NIL)

(fn unregister-capability [_ result ctx]
  (when (and result result.unregisterations)
    (each [_ unregistration (pairs result.unregisterations)]
      (when (= unregistration.method :workspace/didChangeWatchedFiles)
        (mod-invoke :fsouza.lsp.fs-watch :unregister unregistration.id
                    ctx.client_id))))
  vim.NIL)

(local log-files {})

(fn get-log-file [client-name]
  (let [log-file (. log-files client-name)]
    (if log-file
        log-file
        (do
          (let [path (require :fsouza.pl.path)
                log-filename (path.join cache-dir :langservers
                                        (string.format "%s.log" client-name))
                (log-file err) (io.open log-filename :a)]
            (when err
              (error err))
            (tset log-files :client-name log-file)
            log-file)))))

(fn log-message [err result ctx]
  (let [{:client_id client-id} ctx
        client (vim.lsp.get_client_by_id client-id)
        client-name (?. client :name)]
    (when client-name
      (let [log-file (get-log-file client-name)]
        (log-file:write (string.format "%s\n" result.message))
        (log-file:flush)))))

{:textDocument/declaration fzf-location-callback
 :textDocument/definition fzf-location-callback
 :textDocument/typeDefinition fzf-location-callback
 :textDocument/implementation fzf-location-callback
 :textDocument/references (fn [err result ...]
                            (let [result (mod-invoke :fsouza.lsp.references
                                                     :filter-references result)]
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
 :textDocument/publishDiagnostics #(mod-invoke :fsouza.lsp.buf-diagnostic
                                               :publish-diagnostics $...)
 :client/registerCapability register-capability
 :client/unregisterCapability unregister-capability
 :window/logMessage log-message}
