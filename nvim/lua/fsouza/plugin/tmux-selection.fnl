(fn handle [filepath]
  (vim.schedule #(os.remove filepath))
  (vim.cmd.cfile filepath)
  (vim.cmd.copen)
  (vim.cmd.cfirst))

{: handle}
