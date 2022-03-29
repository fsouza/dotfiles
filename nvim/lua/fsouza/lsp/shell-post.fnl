(import-macros {: if-nil : mod-invoke} :helpers)

(fn read-buffer [bufnr]
  (let [lines (table.concat (vim.api.nvim_buf_get_lines bufnr 0 -1 true) "\n")]
    (if (vim.api.nvim_buf_get_option bufnr :eol)
        (.. lines "\n")
        lines)))

(fn notify [bufnr]
  (let [uri (vim.uri_from_bufnr bufnr)
        params {:textDocument {: uri
                               :version (vim.api.nvim_buf_get_changedtick bufnr)}
                :contentChanges [{:text (read-buffer bufnr)}]}]
    (each [_ client (pairs (vim.lsp.buf_get_clients bufnr))]
      (client.notify :textDocument/didChange params))))

(fn augroup-name [bufnr]
  (.. :fsouza__lsp_shell-post_ bufnr))

(fn on-attach [bufnr]
  (mod-invoke :fsouza.lib.nvim-helpers :augroup (augroup-name bufnr)
              [{:events [:FileChangedShellPost]
                :targets [(string.format "<buffer=%d>" bufnr)]
                :callback #(notify bufnr)}]))

(fn on-detach [bufnr]
  (mod-invoke :fsouza.lib.nvim-helpers :reset-augroup (augroup-name bufnr)))

{: on-attach : on-detach}
