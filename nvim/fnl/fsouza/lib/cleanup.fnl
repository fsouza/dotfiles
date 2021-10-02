(import-macros {: vim-schedule} :fsouza-macros)

(fn cleanup [mod]
  (var finished 0)
  (let [{:cbs cbs} mod]
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

(let [mod {:cbs []
           :register (fn [f]
                       (table.insert mod.cbs f))
           :setup (fn []
                    (let [helpers (require "fsouza.lib.nvim-helpers")]
                      (helpers.augroup
                        "fsouza__lua_lib_cleanup"
                        [{:events ["VimLeavePre"]
                          :targets ["*"]
                          :command (helpers.fn-cmd (partial cleanup mod))}])))}]
  mod)
