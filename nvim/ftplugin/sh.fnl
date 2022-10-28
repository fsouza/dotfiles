(import-macros {: mod-invoke} :helpers)
(import-macros {: node-lsp-cmd} :lsp-helpers)

(mod-invoke :fsouza.lsp.servers :start
            {:name :bashls :cmd (node-lsp-cmd :bash-language-server :start)})
