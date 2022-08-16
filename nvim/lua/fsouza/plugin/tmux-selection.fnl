(import-macros {: vim-schedule} :helpers)

(fn handle [filepath]
  (vim-schedule (os.remove filepath))
  (vim.cmd.cfile filepath)
  (vim.cmd.copen)
  (vim.cmd.wincmd :p))

{: handle}
