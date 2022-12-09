(import-macros {: mod-invoke} :helpers)

(mod-invoke :fsouza.lsp.servers :start
            {:name :solargraph :cmd [:solargraph :stdio]})
