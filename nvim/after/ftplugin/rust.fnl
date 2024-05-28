(import-macros {: mod-invoke} :helpers)

(mod-invoke :fsouza.lsp.servers :start
            {:config {:name :rust-analyzer
                      :cmd [(vim.fs.joinpath _G.cache-dir :langservers :bin
                                             :rust-analyzer)]
                      :settings {:rust-analyzer {:checkOnSave {:command :clippy}}}
                      :find-root-dir #(mod-invoke :fsouza.lsp.servers
                                                  :patterns-with-fallback
                                                  [:Cargo.toml])}
             :opts {:autofmt true}})
