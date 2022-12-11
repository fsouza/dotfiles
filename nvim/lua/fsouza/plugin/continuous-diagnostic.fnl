(import-macros {: mod-invoke : if-nil : vim-schedule} :helpers)

(local pids {})

(fn log-chunks [payload]
  (let [{: chunk} payload]
    (print (string.format "chunk=%s" (vim.inspect chunk)))))

(fn stop [name]
  (let [pid (. pids name)]
    (when pid
      (vim-schedule (vim.loop.kill pid vim.loop.constants.SIGTERM))
      (tset pids pid nil))))

(fn start [opts]
  (let [{: name : cmd : args : reset-fn} opts
        ns (vim.api.nvim_create_namespace (string.format "fsouza/continuous/%s"
                                                         name))
        pid (mod-invoke :fsouza.lib.cmd :start cmd {: args} log-chunks #nil)]
    (when pid
      (tset pids name pid)
      (mod-invoke :fsouza.lib.nvim-helpers :augroup
                  (string.format "fsouza__continuous-autokill-%s" name)
                  [{:events [:VimLeavePre]
                    :targets ["*"]
                    :callback #(stop name)}]))))

{: start : stop}
