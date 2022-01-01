(macro render-diagnostics [diagnostics]
  `(let [items# (vim.diagnostic.toqflist ,diagnostics)]
     (vim.diagnostic.setqflist items#)
     (if (vim.tbl_isempty items#)
       (vim.cmd "cclose")
       (do
         (vim.cmd "copen")
         (vim.cmd "wincmd p")
         (vim.cmd "cc")))))

(fn list-file-diagnostics []
  (let [bufnr (vim.api.nvim_get_current_buf)]
    (render-diagnostics (vim.diagnostic.get bufnr))))

(fn list-workspace-diagnostics []
  (render-diagnostics (vim.diagnostic.get)))

{: list-file-diagnostics
 : list-workspace-diagnostics}
