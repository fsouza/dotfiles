(import-macros {: mod-invoke} :helpers)
(import-macros {: get-cache-cmd} :lsp-helpers)

(fn setup []
  (mod-invoke :fsouza.lsp.servers :start
              {:name :gopls :cmd [(get-cache-cmd :gopls)]}
              #(mod-invoke :fsouza.lsp.servers :patterns-with-fallback
                           [:go.mod])))

{: setup}
