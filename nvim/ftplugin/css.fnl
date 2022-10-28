(import-macros {: mod-invoke} :helpers)
(import-macros {: node-lsp-cmd} :lsp-helpers)

(mod-invoke :fsouza.lsp.servers :start
            {:name :cssls
             :cmd (node-lsp-cmd :vscode-css-language-server :--stdio)})
