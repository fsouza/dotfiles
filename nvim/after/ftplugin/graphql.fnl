(import-macros {: mod-invoke} :helpers)

(mod-invoke :fsouza.lsp.servers :start
            {:config {:name :graphql-language-server
                      :cmd [:graphql-lsp :server :-m :stream]}})
