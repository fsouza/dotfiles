(let [servers (require :fsouza.lsp.servers)]
  (servers.start {:config {:name :rust-analyzer
                           :cmd [(vim.fs.joinpath _G.cache-dir :langservers
                                                  :bin :rust-analyzer)]
                           :settings {:rust-analyzer {:checkOnSave {:command :clippy}}}
                           :find-root-dir #(servers.patterns-with-fallback [:Cargo.toml])}
                  :opts {:autofmt true}}))
