(import-macros {: mod-invoke} :helpers)

(let [mod-dir (vim.fs.joinpath _G.dotfiles-dir :nvim :langservers)]
  (mod-invoke :fsouza.lsp.servers :start
              {:config {:name :jsonnet-language-server
                        :cmd [:go
                              :run
                              :-C
                              mod-dir
                              :github.com/grafana/jsonnet-language-server
                              :--lint
                              :--eval-diags]}
               :opts {:autofmt true}}))
