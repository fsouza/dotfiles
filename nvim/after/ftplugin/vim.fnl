(import-macros {: mod-invoke} :helpers)

(mod-invoke :fsouza.lsp.servers :start
            {:config {:name :vim-language-server
                      :cmd [:vim-language-server :--stdio]
                      :init_options {:isNeovim true}}})
