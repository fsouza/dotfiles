(import-macros {: abuf : mod-invoke : vim-schedule} :helpers)

(fn on-FileChangedShell []
  (let [bufnr (abuf)]
    (when bufnr
      (if (= vim.v.fcs_reason :deleted)
          (vim-schedule (mod-invoke :bufdelete :bufwipeout bufnr true))
          (not= vim.v.fcs_reason :conflict)
          (tset vim.v :fcs_choice :reload)))))

(fn setup []
  (mod-invoke :fsouza.lib.nvim-helpers :augroup :fsouza__auto_delete
              [{:events [:FileChangedShell]
                :targets ["*"]
                :callback on-FileChangedShell}]))

{: setup}
