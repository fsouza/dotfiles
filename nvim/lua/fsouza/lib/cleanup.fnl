(import-macros {: vim-schedule : mod-invoke} :helpers)

(fn cleanup [cbs]
  (var finished 0)
  (each [_ cb (ipairs cbs)]
    (vim-schedule (cb) (set finished (+ finished 1))))
  (vim.wait 500 #(= (length cbs) finished) 25))

(let [cbs []]
  {:register (partial table.insert cbs)
   :setup #(mod-invoke :fsouza.lib.nvim-helpers :augroup
                       :fsouza__lua_lib_cleanup
                       [{:events [:VimLeavePre]
                         :targets ["*"]
                         :callback #(cleanup cbs)}])})
