(fn vim-schedule [expr]
  `(vim.schedule (fn []
                   ,expr)))

(fn if-nil [v expr]
  `(if (not= ,v nil)
     ,v
     ,expr))

(fn cmd-map [cmd]
  `(string.format "<cmd>%s<cr>" ,cmd))

(fn vcmd-map [cmd]
  `(string.format "<cmd>'<,'><cr>" ,cmd))

{:vim-schedule vim-schedule
 :if-nil if-nil
 :cmd-map cmd-map
 :vcmd-map vcmd-map}
