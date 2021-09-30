(macro render-diagnostics [items]
  `(do
     (vim.lsp.util.set_qflist ,items)
     (if (vim.tbl_isempty ,items)
       (vim.cmd "close")
       (do
         (vim.cmd "copen")
         (vim.cmd "wincmd p")
         (vim.cmd "cc")))))

(fn list-file-diagnostics []
  (let [bufnr (vim.api.nvim_get_current_buf)
        buf-diagnostics (vim.diagnostic.get bufnr)
        items (vim.diagnostic.toqflist buf-diagnostics)]
    (render-diagnostics items)))

(fn list-workspace-diagnostics []
  (let [diagnostics (vim.diagnostic.get)
        items (vim.diagnostic.toqflist diagnostics)]
    (render-diagnostics items)))

{:list-file-diagnostics list-file-diagnostics
 :list-workspace-diagnostics list-workspace-diagnostics}
