(import-macros {: vim-schedule : if-nil : mod-invoke} :helpers)

(local mapping-per-buf {})

(fn augroup-name [bufnr]
  (.. :fsouza__lsp_codelens_ bufnr))

(fn on-detach [bufnr]
  (let [mappings (. mapping-per-buf bufnr)]
    (when (vim.api.nvim_buf_is_valid bufnr)
      (when mappings
        (vim.keymap.del :n mappings {:buffer bufnr})))
    (let [augroup-id (augroup-name bufnr)
          buf-diagnostic (require :fsouza.lsp.buf-diagnostic)]
      (mod-invoke :fsouza.lib.nvim-helpers :reset-augroup augroup-id)
      (buf-diagnostic.unregister-hook augroup-id))))

(fn on-attach [opts]
  (let [bufnr opts.bufnr
        augroup-id (augroup-name bufnr)]
    (tset mapping-per-buf bufnr opts.mapping)
    (vim.schedule vim.lsp.codelens.refresh)
    (mod-invoke :fsouza.lib.nvim-helpers :augroup augroup-id
                [{:events [:InsertLeave :BufWritePost]
                  :targets [(string.format "<buffer=%d>" bufnr)]
                  :callback vim.lsp.codelens.refresh}])
    (vim-schedule (let [buf-diagnostic (require :fsouza.lsp.buf-diagnostic)]
                    (buf-diagnostic.register-hook augroup-id
                                                  vim.lsp.codelens.refresh)
                    (vim.api.nvim_buf_attach bufnr false
                                             {:on_detach #(on-detach bufnr)})))
    (when opts.mapping
      (vim.keymap.set :n opts.mapping vim.lsp.codelens.run
                      {:silent true :buffer bufnr}))))

{: on-attach : on-detach}
