(fn augroup-name [bufnr]
  (.. :fsouza__lsp_shell-post_ bufnr))

(fn on-attach [bufnr]
  (let [{: augroup} (require :fsouza.lib.nvim-helpers)]
    (augroup (augroup-name bufnr)
             [{:events [:FileChangedShellPost]
               :targets [(string.format "<buffer=%d>" bufnr)]
               :callback #(let [sync (require :fsouza.lsp.sync)]
                            (sync.notify-clients bufnr))}])))

{: on-attach}
