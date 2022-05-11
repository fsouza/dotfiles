(import-macros {: mod-invoke} :helpers)

(fn setup []
  (var should-clear-qf false)

  (fn handle-result [next result]
    (if (= result.exit-status 0)
        (do
          (when should-clear-qf
            (set should-clear-qf false)
            (vim.fn.setqflist [])
            (vim.api.nvim_cmd {:cmd :cclose} {}))
          (vim.notify "Successfully compiled")
          (when next
            (next)))
        (do
          (when (mod-invoke :fsouza.lib.qf :set-from-contents result.stderr
                            {:open true})
            (vim.api.nvim_cmd {:cmd :wincmd :args [:p]} {})
            (set should-clear-qf true)))))

  (fn make []
    (when (not vim.g.fennel_ks)
      (let [file-name (vim.fn.expand :<afile>)
            next (if (vim.endswith file-name :/packed.fnl)
                     #(mod-invoke :fsouza.packed :repack)
                     nil)]
        (mod-invoke :fsouza.lib.cmd :run :make
                    {:args [:-C dotfiles-dir :install]} nil
                    (partial handle-result next)))))

  (mod-invoke :fsouza.lib.nvim-helpers :augroup :fsouza__autocompile-fennel
              [{:events [:BufWritePost]
                :targets [(.. dotfiles-dir :/*.fnl)
                          (.. dotfiles-dir :/nvim/*.vim)]
                :callback make}]))

{: setup}
