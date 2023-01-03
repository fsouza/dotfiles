(import-macros {: mod-invoke} :helpers)

(let [load-git-messenger (mod-invoke :fsouza.lib.nvim-helpers :once
                                     #(vim.cmd.packadd :git-messenger.vim))]
  (vim.keymap.set :n :<leader>gm
                  #(do
                     (load-git-messenger)
                     (vim.cmd.GitMessenger))))
