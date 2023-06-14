(import-macros {: mod-invoke} :helpers)

(let [ts-context-comment-string (require :ts_context_commentstring)]
  (when ts-context-comment-string
    (ts-context-comment-string.init)
    (mod-invoke :Comment :setup {:pre_hook (mod-invoke :ts_context_commentstring.integrations.comment_nvim
                                                       :create_pre_hook)
                                 :ignore #"^$"})))
