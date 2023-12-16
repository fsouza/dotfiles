(import-macros {: mod-invoke} :helpers)

(vim.cmd.packadd :emmet-vim)

(mod-invoke :fsouza.lsp.servers :start
            {:config {:name :htmlls
                      :cmd [:vscode-html-language-server :--stdio]}})
