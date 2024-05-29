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
  (let [rbuf (vim.ringbuf 128)
        debounce (require :fsouza.lib.debounce)
        handler (debounce.debounce 500
                                   (vim.schedule_wrap (. vim.lsp.handlers
                                                         :$/progress)))
        {: augroup} (require :fsouza.lib.nvim-helpers)]
    (fn drain-rbuf []
      (-> rbuf
          (vim.iter)
          (: :each #(let [{: err : result : context} $1]
                      (handler.call err result context)))))

    (tset vim.lsp.handlers :$/progress
          #(let [err $1
                 result $2
                 context $3]
             (if enabled
                 (handler.call err result context)
                 (rbuf:push {: err : result : context}))))
    (augroup :fsouza__auto_disable_progress
             [{:events [:InsertLeave]
               :targets ["*"]
               :callback #(do
                            (drain-rbuf)
                            (set enabled true))}
              {:events [:InsertEnter]
               :targets ["*"]
               :callback #(do
                            (set enabled false)
                            (handler.clear)
                            (vim.cmd.FidgetClose))}])))
