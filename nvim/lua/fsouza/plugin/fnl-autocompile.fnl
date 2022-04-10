(import-macros {: mod-invoke} :helpers)

(fn setup []
  (var should-clear-qf false)

  (fn transform-qf-item [item]
    (tset item :filename (vim.fn.fnamemodify (.. :nvim/ item.filename) ":p"))
    item)

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
                            {:hook transform-qf-item :open true})
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

  (let [home (vim.fn.expand "~")
        dotfiles (mod-invoke :pl.path :join home :.dotfiles)]
    (mod-invoke :fsouza.lib.nvim-helpers :augroup :fsouza__autocompile-fennel
                [{:events [:BufWritePost]
                  :targets [(.. home :/.dotfiles/nvim/*.fnl)
                            (.. home :/.dotfiles/nvim/*.vim)
                            (.. home :/.dotfiles/hammerspoon/*.fnl)
                            (.. home :/.dotfiles/wezterm/*.fnl)]
                  :callback #(make dotfiles)}])))

{: setup}
