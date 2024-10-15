(fn is-go-test [fname]
  (vim.endswith fname :_test.go))

(fn setup []
  (let [bufnr (vim.api.nvim_get_current_buf)
        servers (require :fsouza.lsp.servers)]
    (servers.start {:config {:name :gopls
                             :cmd [(vim.fs.joinpath _G.cache-dir :langservers
                                                    :bin :gopls)]
                             :init_options {:deepCompletion false
                                            :staticcheck true
                                            :analyses {:fillreturns true
                                                       :nonewvars true
                                                       :undeclaredname true
                                                       :unusedparams true
                                                       :ST1000 false}
                                            :linksInHover false
                                            :codelenses {:vendor false}
                                            :gofumpt true
                                            :usePlaceholders false
                                            :experimentalPostfixCompletions false
                                            :completeFunctionCalls false}}
                    :find-root-dir #(servers.patterns-with-fallback [:go.mod]
                                                                    $1)
                    : bufnr
                    :opts {:autofmt true :auto-action :source.organizeImports}
                    :cb #(let [references (require :fsouza.lsp.references)]
                           (references.register-test-checker :.go :go
                                                             is-go-test))})))

{: setup}
