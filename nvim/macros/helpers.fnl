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

(fn vcmd-map [cmd]
  `(string.format "<cmd>'<,'>%s<cr>" ,cmd))

{:vim-schedule vim-schedule
 :if-nil if-nil
 :cmd-map cmd-map
 :vcmd-map vcmd-map}
