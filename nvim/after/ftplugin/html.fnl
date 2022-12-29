(import-macros {: mod-invoke} :helpers)

(mod-invoke :fsouza.lsp.servers :start
            {:config {:name :htmlls
                      :cmd [:vscode-html-language-server :--stdio]}})
