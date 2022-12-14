(fn vim-schedule [...]
  `(vim.schedule (fn []
                   ,...)))

(fn if-nil [...]
  (let [args [...]]
    (fn check [idx]
      (let [arg (. args idx)]
        (if (< idx (length args))
            `(let [v# ,arg]
               (if (not= v# nil)
                   v#
                   ,(check (+ idx 1))))
            arg)))

    (check 1)))

(fn send-esc []
  `(-> :<esc> (vim.api.nvim_replace_termcodes true false true)
       (vim.api.nvim_feedkeys :map true)))

(fn reload [mod-name]
  `(do
     (tset package.loaded ,mod-name nil)
     (require ,mod-name)))

(fn mod-invoke [mod fn-name ...]
  `((. (require ,mod) ,fn-name) ,...))

(fn max-col []
  2147483647)

{: vim-schedule : if-nil : send-esc : reload : mod-invoke : max-col}
