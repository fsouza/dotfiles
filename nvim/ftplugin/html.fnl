(import-macros {: mod-invoke} :helpers)
(import-macros {: node-lsp-cmd} :lsp-helpers)

(mod-invoke :fsouza.lsp.servers :start
            {:name :htmlls
             :cmd (node-lsp-cmd :vscode-html-language-server :--stdio)})
