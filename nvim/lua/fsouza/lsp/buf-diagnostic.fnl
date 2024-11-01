(local debouncers {})

(local hooks {})

(local filters {})

(fn register-filter [client-name f]
  (tset filters client-name f))

(fn filter [result client]
  (when (and result client)
    (let [client-filter (or (. filters (?. client :name)) #true)
          {: diagnostics} result]
      (when (and diagnostics client)
        (tset result :diagnostics
              (-> diagnostics
                  (vim.iter)
                  (: :filter client-filter)
                  (: :totable)))))
    result))

(fn buf-clear-all-diagnostics []
  (let [all-clients (vim.lsp.get_active_clients)]
    (each [_ client (ipairs all-clients)]
      (vim.diagnostic.hide (vim.lsp.diagnostic.get_namespace client.id)))))

;; This is a workaround because the default lsp client doesn't let us hook into
;; textDocument/didChange like coc.nvim does.
(fn exec-hooks []
  (each [_ f (ipairs hooks)]
    (f)))

(fn make-handler []
  (fn [err result context ...]
    (vim.schedule exec-hooks)
    (pcall vim.diagnostic.reset context.client_id context.bufnr)
    (let [client (vim.lsp.get_client_by_id context.client_id)
          result (filter result client)]
      (when client
        (vim.lsp.diagnostic.on_publish_diagnostics err result context ...)))))

(fn make-debounced-handler [bufnr debouncer-key]
  (let [interval-ms (or (. vim :b bufnr :lsp_diagnostic_debouncing_ms) 200)
        debounce (require :fsouza.lib.debounce)
        handler (debounce.debounce interval-ms
                                   (vim.schedule_wrap (make-handler)))]
    (tset debouncers debouncer-key handler)
    (vim.api.nvim_buf_attach bufnr false
                             {:on_detach (fn []
                                           (handler.stop)
                                           (tset debouncers debouncer-key nil))})
    handler))

(fn publish-diagnostics [err result context ...]
  (when result
    (let [uri result.uri
          bufnr (vim.uri_to_bufnr uri)]
      (when bufnr
        (tset context :bufnr bufnr)
        (let [debouncer-key (string.format "%d/%s" context.client_id uri)
              handler (or (. debouncers debouncer-key)
                          (make-debounced-handler bufnr debouncer-key))]
          (handler.call err result context ...))))))

{: buf-clear-all-diagnostics
 : register-filter
 :register-hook #(tset hooks $1 $2)
 :unregister-hook #(tset hooks $1 nil)
 : publish-diagnostics}
