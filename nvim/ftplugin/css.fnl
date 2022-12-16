(import-macros {: mod-invoke} :helpers)

(mod-invoke :fsouza.lsp.servers :start
            {:config {:name :cssls :cmd [:vscode-css-language-server :--stdio]}})
