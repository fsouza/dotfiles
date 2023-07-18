(import-macros {: mod-invoke} :helpers)

(fn fmt-task [task-name message percentage]
  (let [mid (if percentage
                (string.format " (%s%%)" percentage)
                "")
        suffix (if (and task-name (not= task-name ""))
                   (string.format " [%s]" task-name)
                   "")]
    (.. message mid suffix)))

(do
  (mod-invoke :fidget :setup {:window {:blend 0} :fmt {:task fmt-task}})
  (var enabled true)
  (let [progress-handler (. vim.lsp.handlers :$/progress)]
    (fn enable []
      (set enabled true))

    (fn disable []
      (set enabled false))

    (fn handle-progress [...]
      (when enabled
        (progress-handler ...)))

    (tset vim.lsp.handlers :$/progress handle-progress)
    (mod-invoke :fsouza.lib.nvim-helpers :augroup
                :fsouza__auto_disable_progress
                [{:events [:InsertLeave] :targets ["*"] :callback enable}
                 {:events [:InsertEnter] :targets ["*"] :callback disable}])))
