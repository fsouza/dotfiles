(import-macros {: if-nil : mod-invoke} :helpers)

(local debouncers {})

(local hooks {})

(local filters {})

(fn get-filters [client-name]
  (if client-name
      (or (. filters client-name) [])))

(fn register-filter [client-name f]
  (let [client-filters (get-filters client-name)]
    (table.insert client-filters f)
    (tset filters client-name client-filters)))

(fn filter [result context]
  (when result
    (let [client (vim.lsp.get_client_by_id context.client_id)
          client-filters (get-filters (?. client :name))
          {: diagnostics} result]
      (when (and diagnostics client)
        (tset result :diagnostics (icollect [_ d (ipairs diagnostics)]
                                    (when (mod-invoke :fsouza.pl.tablex
                                                      :for-all client-filters
                                                      #($1 d))
                                      d))))
      result)))

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
  (let [handler (vim.lsp.with vim.lsp.diagnostic.on_publish_diagnostics
                              {:underline true
                               :virtual_text false
                               :signs true
                               :update_in_insert false})]
    (fn [err result context ...]
      (vim.schedule exec-hooks)
      (vim.diagnostic.reset context.client_id context.bufnr)
      (let [result (filter result context)]
        (handler err result context ...)))))

(fn make-debounced-handler [bufnr debouncer-key]
  (let [interval-ms (or vim.b.lsp_diagnostic_debouncing_ms 200)
        handler (mod-invoke :fsouza.lib.debounce :debounce interval-ms
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
              handler (if-nil (. debouncers debouncer-key)
                              (make-debounced-handler bufnr debouncer-key))]
          (handler.call err result context ...))))))

{: buf-clear-all-diagnostics
 : register-filter
 :register-hook #(tset hooks $1 $2)
 :unregister-hook #(tset hooks $1 nil)
 : publish-diagnostics}
