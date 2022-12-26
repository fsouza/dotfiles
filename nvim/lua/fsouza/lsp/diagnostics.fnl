(import-macros {: mod-invoke} :helpers)

(var n-diag-per-buf {})

(macro render-diagnostics [diagnostics]
  `(let [items# (vim.diagnostic.toqflist ,diagnostics)]
     (vim.fn.setqflist items#)
     (if (vim.tbl_isempty items#)
         (vim.cmd.cclose)
         (do
           (vim.cmd.copen)
           (vim.cmd.wincmd :p)
           (vim.cmd.cc)))))

(fn list-file-diagnostics []
  (let [bufnr (vim.api.nvim_get_current_buf)]
    (render-diagnostics (vim.diagnostic.get bufnr))))

(fn list-workspace-diagnostics []
  (render-diagnostics (vim.diagnostic.get)))

(fn on-DiagnosticChanged []
  (set n-diag-per-buf (accumulate [acc {} _ {: bufnr} (ipairs (vim.diagnostic.get))]
                        (let [curr (or (. acc bufnr) 0)]
                          (tset acc bufnr (+ curr 1))
                          acc))))

(fn ruler []
  (let [bufnr (vim.api.nvim_get_current_buf)
        count (or (. n-diag-per-buf bufnr) 0)]
    (if (= count 0) "    " (string.format "D:%02d" count))))

(fn on-attach []
  (mod-invoke :fsouza.lib.nvim-helpers :augroup :fsouza__lsp_diagnostic
              [{:events [:DiagnosticChanged]
                :targets ["*"]
                :callback on-DiagnosticChanged}]))

{: list-file-diagnostics : list-workspace-diagnostics : on-attach : ruler}
