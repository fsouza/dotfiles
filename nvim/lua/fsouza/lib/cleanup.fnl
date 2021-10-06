(import-macros {: vim-schedule} :helpers)

(fn cleanup [mod]
  (var finished 0)
  (let [{: cbs} mod]
    (each [_ cb (ipairs cbs)]
      (vim-schedule
        (do
          (cb)
          (set finished (+ finished 1)))))

    (vim.wait
      500
      (fn []
        (= (length cbs) finished))
      25)))

(let [mod {:cbs []}]
  (tset mod :register (partial table.insert mod.cbs))
  (tset mod :setup (fn []
                     (let [helpers (require :fsouza.lib.nvim-helpers)]
                       (helpers.augroup
                         "fsouza__lua_lib_cleanup"
                         [{:events ["VimLeavePre"]
                           :targets ["*"]
                           :command (helpers.fn-cmd (partial cleanup mod))}]))))
  mod)
