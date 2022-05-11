(import-macros {: vim-schedule} :helpers)

(fn handle [filepath]
  (vim-schedule (os.remove filepath))
  (vim.api.nvim_cmd {:cmd :cfile :args [filepath]} {})
  (vim.api.nvim_cmd {:cmd :copen} {})
  (vim.api.nvim_cmd {:cmd :wincmd :args [:p]} {}))

{: handle}
