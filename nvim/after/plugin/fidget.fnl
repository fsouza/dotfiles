(fn fmt-task [task-name message percentage]
  (let [mid (if percentage
                (string.format " (%s%%)" percentage)
                "")
        suffix (if (and task-name (not= task-name ""))
                   (string.format " [%s]" task-name)
                   "")]
    (.. message mid suffix)))

(let [fidget (require :fidget)]
  (fidget.setup {:window {:blend 0} :fmt {:task fmt-task}})
  (var enabled true)
  (let [debounce (require :fsouza.lib.debounce)
        handler (debounce.debounce 500
                                   (vim.schedule_wrap (. vim.lsp.handlers
                                                         :$/progress)))
        {: augroup} (require :fsouza.lib.nvim-helpers)]
    (tset vim.lsp.handlers :$/progress
          #(when enabled
             (handler.call $...)))
    (augroup :fsouza__auto_disable_progress
             [{:events [:InsertLeave]
               :targets ["*"]
               :callback #(set enabled true)}
              {:events [:InsertEnter]
               :targets ["*"]
               :callback #(do
                            (set enabled false)
                            (vim.cmd.FidgetClose))}])))
