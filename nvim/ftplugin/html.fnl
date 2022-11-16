(import-macros {: mod-invoke} :helpers)

(mod-invoke :fsouza.lsp.servers :start
            {:name :htmlls :cmd [:vscode-html-language-server :--stdio]})
