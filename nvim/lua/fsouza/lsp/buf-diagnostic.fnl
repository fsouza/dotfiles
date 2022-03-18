(import-macros {: if-nil} :helpers)

(local debouncers {})

(local hooks {})

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
      (handler err result context ...))))

(fn make-debounced-handler [bufnr debouncer-key]
  (let [debounce (require :fsouza.lib.debounce)
        interval-ms (if-nil vim.b.lsp_diagnostic_debouncing_ms 250)
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
    (let [helpers (require :fsouza.lib.nvim-helpers)
          uri result.uri
          bufnr (vim.uri_to_bufnr uri)]
      (when bufnr
        (tset context :bufnr bufnr)
        (let [debouncer-key (string.format "%d/%s" context.client_id uri)
              handler (if-nil (. debouncers debouncer-key)
                              (make-debounced-handler bufnr debouncer-key))]
          (handler.call err result context ...))))))

{: buf-clear-all-diagnostics
 :register-hook (fn [id f]
                  (tset hooks id f))
 :unregister-hook (fn [id]
                    (tset hooks id nil))
 : publish-diagnostics}
