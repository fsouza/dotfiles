(import-macros {: mod-invoke} :helpers)
(import-macros {: get-cache-cmd} :lsp-helpers)

(mod-invoke :fsouza.lsp.servers :start
            {:name :rust-analyzer
             :cmd [(get-cache-cmd :rust-analyzer)]
             :settings {:rust-analyzer {:checkOnSave {:command :clippy}}}})
