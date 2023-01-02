(fn read-buffer [bufnr]
  (let [lines (table.concat (vim.api.nvim_buf_get_lines bufnr 0 -1 true) "\n")]
    (if (. vim :bo bufnr :eol)
        (.. lines "\n")
        lines)))

(fn notify-clients [bufnr]
  (let [uri (vim.uri_from_bufnr bufnr)
        params {:textDocument {: uri
                               :version (vim.api.nvim_buf_get_changedtick bufnr)}
                :contentChanges [{:text (read-buffer bufnr)}]}]
    (each [_ client (pairs (vim.lsp.get_active_clients {: bufnr}))]
      (client.notify :textDocument/didChange params))))

(fn sync-all-buffers []
  (each [_ bufnr (ipairs (vim.api.nvim_list_bufs))]
    (notify-clients bufnr)))

{: notify-clients : sync-all-buffers}
