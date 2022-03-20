(import-macros {: if-nil} :helpers)

(local helpers (require :fsouza.lib.nvim-helpers))

(local clients-by-buf {})

(fn read-buffer [bufnr]
  (let [lines (table.concat (vim.api.nvim_buf_get_lines bufnr 0 -1 true) "\n")]
    (if (vim.api.nvim_buf_get_option bufnr :eol)
        (.. lines "\n")
        lines)))

(fn notify [bufnr]
  (when (. clients-by-buf bufnr)
    (let [uri (vim.uri_from_bufnr bufnr)
          params {:textDocument {: uri
                                 :version (vim.api.nvim_buf_get_changedtick bufnr)}
                  :contentChanges [{:text (read-buffer bufnr)}]}]
      (each [_ client (ipairs (. clients-by-buf bufnr))]
        (client.notify :textDocument/didChange params)))))

(fn buf-attach-if-needed [bufnr]
  (when (not (. clients-by-buf bufnr))
    (vim.api.nvim_buf_attach bufnr false
                             {:on_detach #(tset clients-by-buf bufnr nil)})))

(fn augroup-name [bufnr]
  (.. :fsouza__lsp_shell-post_ bufnr))

(fn on-attach [opts]
  (let [{: bufnr : client} opts
        buf-clients (if-nil (. clients-by-buf bufnr) [])]
    (buf-attach-if-needed bufnr)
    (table.insert buf-clients client)
    (tset clients-by-buf bufnr buf-clients)
    (helpers.augroup (augroup-name bufnr)
                     [{:events [:FileChangedShellPost]
                       :targets [(string.format "<buffer=%d>" bufnr)]
                       :callback #(notify bufnr)}])))

(fn on-detach [bufnr]
  (tset clients-by-buf bufnr nil)
  (helpers.reset-augroup (augroup-name bufnr)))

{: on-attach : on-detach}
