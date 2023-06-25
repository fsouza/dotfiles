(import-macros {: mod-invoke} :helpers)

(mod-invoke :fsouza.lsp.servers :start
            {:config {:name :taplo :cmd [:taplo :lsp :stdio]}
             :opts {:autofmt true}})
