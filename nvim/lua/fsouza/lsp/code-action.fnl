(fn handle-actions [actions]
  (when (and actions (not (vim.tbl_isempty actions)))
    (let [lines (icollect [_ action (ipairs actions)]
                  action.title)
          popup-picker (require :fsouza.lib.popup-picker)]

      (popup-picker.open
        lines
        (fn [index]
          (let [action-chosen (. actions index)]
            (if (or action-chosen.edit (= (type action-chosen.command) "table"))
              (do
                (when action-chosen.edit
                  (vim.lsp.util.apply_workspace_edit action-chosen.edit))
                (when (= (type action-chosen.command) "table")
                  (vim.lsp.buf.execute_command action-chosen.command)))
              (vim.lsp.buf.execute_command action-chosen))))))))

(fn code-action-for-buf []
  (let [bufnr (vim.api.nvim_get_current_buf)
        line-count (vim.api.nvim_buf_line_count bufnr)]
    (vim.lsp.buf.range_code-action {:diagnostics (vim.diagnostic.get bufnr)} [1 1] [line-count 2147483647])))

(fn code-action-for-line [cb]
  (let [(lnum _) (unpack (vim.api.nvim_win_get_cursor 0))
        context {:diagnostics (vim.diagnostic.get 0 {:lnum (- lnum 1)})}
        params (vim.lsp.util.make_range_params)]
    (tset params :context context)
    (vim.lsp.buf_request 0 "textDocument/codeAction" params cb)))

(fn code-action []
  (tset vim.lsp.handlers "textDocument/codeAction" (fn [_ actions]
                                                     (handle-actions actions)))

  (code-action-for-line (fn [_ actions]
                          (if (and actions (not (vim.tbl_isempty actions)))
                            (handle-actions actions)
                            (code-action-for-buf)))))

(fn visual-code-action []
  (tset vim.lsp.handlers "textDocument/codeAction" (fn [_ actions]
                                                     (handle-actions actions)))

  (when (not= (vim.fn.visualmode) "")
    (vim.api.nvim_input "<esc>")
    (let [start-pos (vim.fn.getpos "'<")
          end-pos (vim.fn.getpos "'>")]
      (vim.lsp.buf.range_code-action nil [(. start-pos 2) (. start-pos 3)] [(. end-pos 2) (. end-pos 3)]))))

{:code-action code-action
 :visual-code-action visual-code-action}
