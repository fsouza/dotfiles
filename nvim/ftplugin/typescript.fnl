(import-macros {: mod-invoke} :helpers)

(mod-invoke :fsouza.lsp.servers :start
            {:config {:name :typescript-language-server
                      :cmd [:typescript-language-server :--stdio]}})
