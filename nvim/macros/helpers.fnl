(fn vim-schedule [...]
  `(vim.schedule (fn []
                   ,...)))

(fn if-nil [v expr]
  `(if (not= ,v nil)
     ,v
     ,expr))

(fn cmd-map [cmd]
  `(string.format "<cmd>%s<cr>" ,cmd))

(fn vcmd-map [cmd]
  `(string.format "<cmd>'<,'>%s<cr>" ,cmd))

{:vim-schedule vim-schedule
 :if-nil if-nil
 :cmd-map cmd-map
 :vcmd-map vcmd-map}
