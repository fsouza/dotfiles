(import-macros {: mod-invoke} :helpers)
(import-macros {: get-cache-cmd} :lsp-helpers)

(fn is-go-test [fname]
  (vim.endswith fname :_test.go))

(fn setup []
  (let [bufnr (vim.api.nvim_get_current_buf)]
    (mod-invoke :fsouza.lsp.servers :start
                {:config {:name :gopls
                          :cmd [(get-cache-cmd :gopls)
                                :-remote=auto
                                "-debug=:0"
                                "-remote.debug=:0"]
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
                 :find-root-dir #(mod-invoke :fsouza.lsp.servers
                                             :patterns-with-fallback [:go.mod])
                 : bufnr
                 :opts {:autofmt true :auto-action true}})))

{: setup}
