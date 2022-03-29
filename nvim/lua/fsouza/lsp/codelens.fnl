(import-macros {: vim-schedule : if-nil : mod-invoke} :helpers)

(local debouncers {})

(local ns (vim.api.nvim_create_namespace :fsouza__codelens))

;; stores result by bufnr & line (range.start.line)
(local code-lenses {})

(local mapping-per-buf {})

(fn supports-command [client]
  (not= client.server_capabilities.executeCommandProvider nil))

(fn supports-resolve [client]
  (not= (?. client.server_capabilities :codeLensProvider :resolveProvider) nil))

(fn group-by-line [codelenses by-line]
  (let [to-resolve []
        by-line (if-nil by-line {})]
    (each [_ codelens (ipairs codelenses)]
      (if codelens.command
          (let [line-id codelens.range.start.line
                curr (if-nil (. by-line line-id) [])]
            (table.insert curr codelens)
            (tset by-line line-id curr))
          (table.insert to-resolve codelens)))
    (values by-line to-resolve)))

(fn remove-results [bufnr]
  (tset code-lenses bufnr nil))

(fn resolve-code-lenses [client lenses cb]
  (if (not (supports-resolve client))
      (cb {})
      (let [resolved-lenses []
            timer (vim.loop.new_timer)]
        (var done 0)
        (each [_ lens (ipairs lenses)]
          (client.request :codeLens/resolve lens
                          (fn [_ result]
                            (set done (+ done 1))
                            (when result
                              (table.insert resolved-lenses result)))))
        (timer:start 500 500
                     (vim.schedule_wrap #(when (= done (length lenses))
                                           (timer:close)
                                           (cb resolved-lenses)))))))

(fn render-virtual-text [bufnr]
  (vim.api.nvim_buf_clear_namespace bufnr ns 0 -1)
  (let [prefix " "
        {:lenses buf-lenses} (. code-lenses bufnr)]
    (each [line items (pairs buf-lenses)]
      (let [titles (icollect [_ item (ipairs items)]
                     item.command.title)
            chunks [[(string.format "%s%s" prefix (table.concat titles " | "))
                     :LspCodeLensVirtualText]]]
        (vim.api.nvim_buf_set_virtual_text bufnr ns line chunks {})))))

(fn codelenses-handler [_ codelenses context]
  (when codelenses
    (let [(preresolved to-resolve) (group-by-line codelenses)
          client (vim.lsp.get_client_by_id context.client_id)
          handle-lenses (fn [lenses]
                          (tset code-lenses context.bufnr
                                {: lenses :client-id client.id})
                          (render-virtual-text context.bufnr))]
      (when client
        (if (> (length to-resolve) 0)
            (resolve-code-lenses client to-resolve
                                 #(handle-lenses (group-by-line $1 preresolved)))
            (handle-lenses preresolved))))))

(fn codelenses [bufnr]
  (let [client (mod-invoke :fsouza.lsp.clients :get-client bufnr
                           :codeLensProvider)
        bufnr (if (not= bufnr 0)
                  bufnr
                  (vim.api.nvim_get_current_buf))
        params {:textDocument {:uri (vim.uri_from_bufnr bufnr)}}]
    (client.request :textDocument/codeLens params codelenses-handler bufnr)))

(fn make-debounced-codelenses [bufnr debouncer-key]
  (let [interval-ms (if-nil vim.b.lsp_codelens_debouncing_ms 50)
        debounce (require :fsouza.lib.debounce)
        debounced (debounce.debounce interval-ms (vim.schedule_wrap codelenses))]
    (tset debouncers debouncer-key debounced)
    (vim.api.nvim_buf_attach bufnr false
                             {:on_detach (fn []
                                           (debounced.stop)
                                           (tset debouncers debouncer-key nil))})
    debounced))

(fn codelens [bufnr]
  (let [debouncer-key bufnr
        debounced (if-nil (. debouncers debouncer-key)
                          (make-debounced-codelenses bufnr debouncer-key))]
    (debounced.call bufnr)))

(fn execute-codelenses [bufnr items client]
  (when (and (not (vim.tbl_isempty items)) client)
    (let [run (fn [clens]
                (client.request :workspace/executeCommand clens.command
                                (fn [err]
                                  (when (not err)
                                    (vim.cmd :checktime)))))
          execute-item (fn [selected]
                         (when (and (supports-command client)
                                    (not= selected.command.command ""))
                           (run selected)))]
      (if (> (length items) 1)
          (let [tablex (require :fsouza.tablex)
                popup-picker (require :fsouza.lib.popup-picker)
                popup-lines (tablex.filter-map (fn [item]
                                                 (when item.command
                                                   item.command.title))
                                               items)]
            (popup-picker.open popup-lines #(execute-item (. items $1))))
          (execute-item (. items 1))))))

(fn execute []
  (let [winid (vim.api.nvim_get_current_win)
        bufnr (vim.api.nvim_get_current_buf)
        [line-no _] (vim.api.nvim_win_get_cursor winid)
        line-id (- line-no 1)
        {: lenses : client-id} (if-nil (. code-lenses bufnr) {})
        line-codelenses (?. lenses line-id)
        client (vim.lsp.get_client_by_id client-id)]
    (when (and line-codelenses client)
      (execute-codelenses bufnr line-codelenses client))))

(fn augroup-name [bufnr]
  (.. :fsouza__lsp_codelens_ bufnr))

(fn on-detach [bufnr]
  (let [mappings (. mapping-per-buf bufnr)]
    (when (vim.api.nvim_buf_is_valid bufnr)
      (vim.api.nvim_buf_clear_namespace bufnr ns 0 -1)
      (when mappings
        (vim.keymap.del :n mappings {:buffer bufnr})))
    (let [augroup-id (augroup-name bufnr)
          buf-diagnostic (require :fsouza.lsp.buf-diagnostic)]
      (mod-invoke :fsouza.lib.nvim-helpers :reset-augroup augroup-id)
      (buf-diagnostic.unregister-hook augroup-id)
      (remove-results bufnr))))

(fn on-attach [opts]
  (let [bufnr opts.bufnr
        augroup-id (augroup-name bufnr)]
    (tset mapping-per-buf bufnr opts.mapping)
    (vim-schedule (codelens bufnr))
    (mod-invoke :fsouza.lib.nvim-helpers :augroup augroup-id
                [{:events [:InsertLeave :BufWritePost]
                  :targets [(string.format "<buffer=%d>" bufnr)]
                  :callback #(codelens bufnr)}])
    (vim-schedule (let [buf-diagnostic (require :fsouza.lsp.buf-diagnostic)]
                    (buf-diagnostic.register-hook augroup-id #(codelens bufnr))
                    (vim.api.nvim_buf_attach bufnr false
                                             {:on_detach #(on-detach bufnr)})))
    (when opts.mapping
      (vim.keymap.set :n opts.mapping execute {:silent true :buffer bufnr}))))

{: on-attach : on-detach}
