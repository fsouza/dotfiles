(import-macros {: if-nil : mod-invoke : max-col} :helpers)

(fn do-action [client action resolved]
  (if (or action.edit (= (type action.command) :table))
      (do
        (when action.edit
          (vim.lsp.util.apply_workspace_edit action.edit client.offset_encoding))
        (when (= (type action.command) :table)
          (vim.lsp.buf.execute_command action.command)))
      (not resolved)
      (client.request :codeAction/resolve action
                      (fn [_ resolved-action]
                        (do-action client resolved-action true)))
      (vim.lsp.buf.execute_command action)))

(fn handle-actions [actions client]
  (when (and actions (not (vim.tbl_isempty actions)))
    (let [lines (icollect [_ action (ipairs actions)]
                  action.title)]
      (mod-invoke :fsouza.lib.popup-picker :open lines
                  #(when $1
                     (do-action client (. actions $1)))))))

(fn handler [_ actions context]
  (let [client (vim.lsp.get_client_by_id context.client_id)]
    (handle-actions actions client)))

(fn range-code-action [context start-pos end-pos cb]
  (let [context (if-nil context
                        {:diagnostics (vim.lsp.diagnostic.get_line_diagnostics)})
        params (vim.lsp.util.make_given_range_params start-pos end-pos)]
    (tset params :context context)
    (vim.lsp.buf_request 0 :textDocument/codeAction params cb)))

(fn code-action-for-buf [cb]
  (let [bufnr (vim.api.nvim_get_current_buf)
        line-count (vim.api.nvim_buf_line_count bufnr)
        context {:diagnostics (vim.diagnostic.get bufnr)}
        start-pos [1 1]
        end-pos [line-count (max-col)]]
    (range-code-action context start-pos end-pos cb)))

(fn code-action-for-line [cb]
  (let [context {:diagnostics (vim.lsp.diagnostic.get_line_diagnostics)}
        params (vim.lsp.util.make_range_params)]
    (tset params :context context)
    (vim.lsp.buf_request 0 :textDocument/codeAction params cb)))

(fn code-action []
  (code-action-for-line (fn [err actions ...]
                          (if (and actions (not (vim.tbl_isempty actions)))
                              (handler err actions ...)
                              (code-action-for-buf handler)))))

(fn visual-code-action []
  (let [[srow scol erow ecol] (mod-invoke :fsouza.lib.nvim-helpers
                                          :get-visual-selection-range)]
    (range-code-action nil [srow scol] [erow ecol] handler)))

{: code-action : visual-code-action}
