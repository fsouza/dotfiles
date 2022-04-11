(import-macros {: mod-invoke} :helpers)

(fn setup []
  (var should-clear-qf false)

  (fn handle-result [next result]
    (if (= result.exit-status 0)
        (do
          (when should-clear-qf
            (set should-clear-qf false)
            (vim.fn.setqflist [])
            (vim.cmd :cclose))
          (vim.notify "Successfully compiled")
          (when next
            (next)))
        (do
          (when (mod-invoke :fsouza.plugin.qf :set-from-contents result.stderr
                            {:open true})
            (vim.cmd "wincmd p")
            (set should-clear-qf true)))))

  (fn make [dotfiles-dir]
    (when (not vim.g.fennel_ks)
      (let [file-name (vim.fn.expand :<afile>)
            next (if (vim.endswith file-name :/packed.fnl)
                     #(mod-invoke :fsouza.packed :repack)
                     nil)]
        (mod-invoke :fsouza.lib.cmd :run :make
                    {:args [:-C dotfiles-dir :install]} nil
                    (partial handle-result next)))))

  (let [dotfiles (mod-invoke :pl.path :join (vim.fn.expand "~") :.dotfiles)]
    (mod-invoke :fsouza.lib.nvim-helpers :augroup :fsouza__autocompile-fennel
                [{:events [:BufWritePost]
                  :targets [(.. dotfiles :/*.fnl) (.. dotfiles :/nvim/*.vim)]
                  :callback #(make dotfiles)}])))

{: setup}
