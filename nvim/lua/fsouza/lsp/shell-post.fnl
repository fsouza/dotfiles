(import-macros {: mod-invoke} :helpers)

(fn augroup-name [bufnr]
  (.. :fsouza__lsp_shell-post_ bufnr))

(fn on-attach [bufnr]
  (mod-invoke :fsouza.lib.nvim-helpers :augroup (augroup-name bufnr)
              [{:events [:FileChangedShellPost]
                :targets [(string.format "<buffer=%d>" bufnr)]
                :callback #(mod-invoke :fsouza.lsp.sync :notify-clients bufnr)}]))

{: on-attach}
