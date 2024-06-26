(fn on-FileChangedShell [{: buf}]
  (if (= vim.v.fcs_reason :deleted)
      (vim.schedule #(vim.cmd.bwipeout {:range [buf] :bang true}))
      (not= vim.v.fcs_reason :conflict)
      (tset vim.v :fcs_choice :reload)))

(let [{: augroup} (require :fsouza.lib.nvim-helpers)]
  (augroup :fsouza__auto_delete
           [{:events [:FileChangedShell]
             :targets ["*"]
             :callback on-FileChangedShell}]))
