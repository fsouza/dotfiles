(fn vim-schedule [expr]
  `(vim.schedule (fn []
                   ,expr)))

(fn if-nil [v expr]
  `(if (not= ,v nil)
     ,v
     ,expr))

{:vim-schedule vim-schedule
 :if-nil if-nil}
