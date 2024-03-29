(import-macros {: mod-invoke} :helpers)
(import-macros {: get-cache-cmd} :lsp-helpers)

(mod-invoke :fsouza.lsp.servers :start
            {:config {:name :rust-analyzer
                      :cmd [(get-cache-cmd :rust-analyzer)]
                      :settings {:rust-analyzer {:checkOnSave {:command :clippy}}}
                      :find-root-dir #(mod-invoke :fsouza.lsp.servers
                                                  :patterns-with-fallback
                                                  [:Cargo.toml])}
             :opts {:autofmt true}})
