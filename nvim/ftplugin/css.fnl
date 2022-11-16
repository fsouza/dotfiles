(import-macros {: mod-invoke} :helpers)

(mod-invoke :fsouza.lsp.servers :start
            {:name :cssls :cmd [:vscode-css-language-server :--stdio]})
