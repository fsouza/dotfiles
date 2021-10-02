(fn vim-schedule [expr]
  `(vim.schedule (fn []
                   ,expr)))

{:vim-schedule vim-schedule}
