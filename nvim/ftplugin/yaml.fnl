(import-macros {: mod-invoke} :helpers)

(mod-invoke :fsouza.lsp.servers :start
            {:name :yaml-language-server :cmd [:yaml-language-server :--stdio]})
