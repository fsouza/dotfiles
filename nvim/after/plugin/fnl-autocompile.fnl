(let [{: augroup} (require :fsouza.lib.nvim-helpers)]
  (var should-clear-qf false)

  (fn handle-result [result]
    (if (= result.code 0)
        (do
          (when should-clear-qf
            (set should-clear-qf false)
            (vim.fn.setqflist [])
            (vim.cmd.cclose))
          (vim.notify "Successfully compiled"))
        (let [qf (require :fsouza.lib.qf)]
          (when (qf.set-from-contents result.stderr {:open true})
            (vim.cmd.wincmd :p)
            (set should-clear-qf true)))))

  (fn make [{: file}]
    (when (not vim.g.fennel_ks)
      (vim.system [:make :-C _G.dotfiles-dir :install] nil
                  (vim.schedule_wrap handle-result))))

  (augroup :fsouza__autocompile-fennel
           [{:events [:BufWritePost]
             :targets [(.. _G.dotfiles-dir :/*.fnl)
                       (.. _G.dotfiles-dir :/nvim/*.scm)
                       (.. _G.dotfiles-dir :/nvim/*.vim)]
             :callback make}]))
