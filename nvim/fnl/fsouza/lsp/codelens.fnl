(import-macros {: vim-schedule : if-nil} :fsouza-macros)

(local helpers (require "fsouza.lib.nvim-helpers"))

(local debouncers {})

(local clients {})

(local ns (vim.api.nvim_create_namespace "fsouza__codelens"))

;; stores result by bufnr & line (range.start.line)
(local code-lenses {})

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
  (if (not client.supports-resolve)
    (cb {})
    (let [resolved-lenses []
          timer (vim.loop.new_timer)]
      (var done 0)
      (each [_ lens (ipairs lenses)]
        (client.lsp-client.request
          "codeLens/resolve"
          lens
          (fn [_ result]
            (set done (+ done 1))
            (when result
              (table.insert resolved-lenses result)))))

      (timer:start 500 500 (vim.schedule_wrap (fn []
                                                (when (= done (length lenses))
                                                  (timer:close)
                                                  (cb resolved-lenses))))))))

(fn render-virtual-text [bufnr]
  (vim.api.nvim_buf_clear_namespace bufnr ns 0 -1)
  (let [prefix " "
        buf-lenses (. code-lenses bufnr)]
    (each [line items (pairs buf-lenses)]
      (let [titles (icollect [_ item (ipairs items)]
                     item.command.title)
            chunks [[(string.format "%s%s" prefix (table.concat titles " | ")) "LspCodeLensVirtualText"]]]
        (vim.api.nvim_buf_set_virtual_text bufnr ns line chunks {})))))

(fn codelenses-handler [_ codelenses context]
  (when codelenses
    (let [(preresolved to-resolve) (group-by-line codelenses)
          client (. clients context.bufnr)
          handle-lenses (fn [lenses]
                          (tset code-lenses context.bufnr lenses)
                          (render-virtual-text context.bufnr))]
      (if (> (length to-resolve) 0)
        (resolve-code-lenses client to-resolve (fn [lenses]
                                                 (handle-lenses (group-by-line lenses preresolved))))
        (handle-lenses preresolved)))))

(fn codelenses [bufnr]
  (when (. clients bufnr)
    (let [bufnr (if (not= bufnr 0)
                  bufnr
                  (vim.api.nvim_get_current_buf))
          params {:textDocument {:uri (vim.uri_from_bufnr bufnr)}}
          client (. clients bufnr)]
      (client.lsp-client.request "textDocument/codeLens" params codelenses-handler bufnr))))

(fn make-debounced-codelenses [bufnr debouncer-key]
  (let [interval-ms (if-nil vim.b.lsp_codelens_debouncing_ms 50)
        debounce (require "fsouza.lib.debounce")
        debounced (debounce.debounce interval-ms (vim.schedule_wrap codelenses))]
    (tset debouncers debouncer-key debounced)
    (vim.api.nvim_buf_attach bufnr false {:on_detach (fn []
                                                       (debounced.stop)
                                                       (tset debouncers debouncer-key nil))})
    debounced))

(fn codelens [bufnr]
  (let [debouncer-key bufnr
        debounced (if-nil (. debouncers debouncer-key) (make-debounced-codelenses bufnr debouncer-key))]
    (debounced.call bufnr)))

(fn execute-codelenses [bufnr items]
  (let [client (. clients bufnr)]
    (when (and (not (vim.tbl_isempty items)) client)
      (let [run (fn [clens]
                  (client.lsp-client.request "workspace/executeCommand" clens.command (fn [err]
                                                                                        (when (not err)
                                                                                          (vim.cmd "checktime")))))
            execute-item (fn [selected]
                           (when (and client.supports-command (not= selected.command.command ""))
                             (run selected)))]
        (if (> (length items) 1)
          (let [tablex (require "fsouza.tablex")
                popup-picker (require "fsouza.lib.popup-picker")
                popup-lines (tablex.filter-map (fn [item]
                                                 (when item.command
                                                   item.command.title)))]
            (popup-picker.open popup-lines (fn [index]
                                             (execute-item (. items index)))))
          (execute-item (. items 1)))))))

(fn execute []
  (let [winid (vim.api.nvim_get_current_win)
        bufnr (vim.api.nvim_get_current_buf)
        cursor (vim.api.nvim_win_get_cursor winid)
        line-id (- (. cursor 1) 1)
        buffer-results (if-nil (. code-lenses bufnr) {})
        line-codelenses (. buffer-results line-id)]
    (when line-codelenses
      (execute-codelenses bufnr line-codelenses))))

(fn augroup-name [bufnr]
  (.. "fsouza__lsp_codelens_" bufnr))

(fn on-detach [bufnr]
  (let [mappings (?. clients bufnr :mappings)]
    (when (vim.api.nvim_buf_is_valid bufnr)
      (vim.api.nvim_buf_clear_namespace bufnr ns 0 -1)
      (when mappings
        (helpers.remove-mappings {:n [{:lhs mappings}]} bufnr)))

    (tset clients bufnr nil)
    (let [augroup-id (augroup-name bufnr)
          buf-diagnostic (require "fsouza.lsp.buf-diagnostic")]
      (helpers.reset-augroup augroup-id)
      (buf-diagnostic.unregister-hook augroup-id)
      (remove-results bufnr))))

(fn on-attach [opts]
  (let [bufnr opts.bufnr
        client opts.client
        augroup-id (augroup-name bufnr)]
    (tset clients bufnr {:lsp-client client
                         :supports-resolve opts.can-resolve
                         :supports-command opts.supports-command
                         :mapping opts.mapping})
    (vim-schedule (codelens bufnr))

    (helpers.augroup augroup-id [{:events ["InsertLeave" "BufWritePost"]
                                  :targets [(string.format "<buffer=%d>" bufnr)]
                                  :command (helpers.fn-cmd (partial codelens bufnr))}])

    (vim-schedule
      (let [buf-diagnostic (require "fsouza.lsp.buf-diagnostic")]
        (buf-diagnostic.register-hook augroup-id (partial codelens bufnr))
        (vim.api.nvim_buf_attach bufnr false {:on_detach (partial on-detach bufnr)})))

    (when opts.mapping
      (helpers.create-mappings
        {:n [{:lhs opts.mapping
              :rhs (helpers.fn-map execute)
              :opts {:silent true}}]}
        bufnr))))

{:on-attach on-attach
 :on-detach on-detach}
