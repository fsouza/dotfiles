(fn vim-schedule [...]
  `(vim.schedule (fn []
                   ,...)))

(fn if-nil [...]
  (let [args [...]]
    (fn check [idx]
      (let [arg (. args idx)]
        (if (< idx (length args))
          (list (sym :if)
                (list (sym :not=) arg (sym :nil))
                arg
                (check (+ idx 1)))
          (if (= idx (length args))
            arg
            nil))))

    (check 1)))

(fn cmd-map [cmd]
  `(string.format "<cmd>%s<cr>" ,cmd))

(fn send-esc []
  `(-> "<esc>"
       (vim.api.nvim_replace_termcodes true false true)
       (vim.api.nvim_feedkeys "map" true)))

{: vim-schedule
 : if-nil
 : cmd-map
 : send-esc}
