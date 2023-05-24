(import-macros {: mod-invoke} :helpers)

(mod-invoke :Comment :setup {:pre_hook (mod-invoke :ts_context_commentstring.integrations.comment_nvim
                                                   :create_pre_hook)
                             :ignore #"^$"})
