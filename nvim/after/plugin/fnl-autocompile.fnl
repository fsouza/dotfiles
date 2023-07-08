(import-macros {: mod-invoke} :helpers)

(do
  (var should-clear-qf false)
  (fn handle-result [result]
    (if (= result.exit-status 0)
        (do
          (when should-clear-qf
            (set should-clear-qf false)
            (vim.fn.setqflist [])
            (vim.cmd.cclose))
          (vim.notify "Successfully compiled"))
        (do
          (when (mod-invoke :fsouza.lib.qf :set-from-contents result.stderr
                            {:open true})
            (vim.cmd.wincmd :p)
            (set should-clear-qf true)))))

  (fn make [{: file}]
    (when (not vim.g.fennel_ks)
      (mod-invoke :fsouza.lib.cmd :run :make
                  {:args [:-C _G.dotfiles-dir :install]} handle-result)))

  (mod-invoke :fsouza.lib.nvim-helpers :augroup :fsouza__autocompile-fennel
              [{:events [:BufWritePost]
                :targets [(.. _G.dotfiles-dir :/*.fnl)
                          (.. _G.dotfiles-dir :/nvim/*.scm)
                          (.. _G.dotfiles-dir :/nvim/*.vim)]
                :callback make}]))
