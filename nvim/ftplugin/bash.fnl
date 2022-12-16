(import-macros {: mod-invoke} :helpers)

(mod-invoke :fsouza.lsp.servers :start
            {:config {:name :bashls :cmd [:bash-language-server :start]}})
