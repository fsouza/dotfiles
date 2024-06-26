(let [mod-dir (vim.fs.joinpath _G.dotfiles-dir :nvim :langservers)
      servers (require :fsouza.lsp.servers)]
  (servers.start {:config {:name :jsonnet-language-server
                           :cmd [:go
                                 :run
                                 :-C
                                 mod-dir
                                 :github.com/grafana/jsonnet-language-server
                                 :--lint
                                 :--eval-diags]}
                  :opts {:autofmt true}}))
