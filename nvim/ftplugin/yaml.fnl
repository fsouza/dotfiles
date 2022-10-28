(import-macros {: mod-invoke} :helpers)
(import-macros {: node-lsp-cmd} :lsp-helpers)

(mod-invoke :fsouza.lsp.servers :start
            {:name :yaml-language-server
             :cmd (node-lsp-cmd :yaml-language-server :--stdio)})
