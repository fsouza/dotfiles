(import-macros {: mod-invoke} :helpers)

(mod-invoke :fsouza.lsp.servers :start
            {:config {:name :yaml-language-server
                      :cmd [:yaml-language-server :--stdio]
                      :settings {:yaml {:keyOrdering false
                                        :schemaStore {:enable true}}}}})
