(import-macros {: mod-invoke} :helpers)
(import-macros {: get-cache-cmd} :lsp-helpers)

(fn setup []
  (mod-invoke :fsouza.lsp.servers :start
              {:name :gopls
               :cmd [(get-cache-cmd :gopls)]
               :init_options {:deepCompletion false
                              :staticcheck true
                              :analyses {:fillreturns true
                                         :nonewvars true
                                         :undeclaredname true
                                         :unusedparams true
                                         :ST1000 false}
                              :linksInHover false
                              :codelenses {:vendor false}
                              :gofumpt true}}
              #(mod-invoke :fsouza.lsp.servers :patterns-with-fallback
                           [:go.mod])))

{: setup}
