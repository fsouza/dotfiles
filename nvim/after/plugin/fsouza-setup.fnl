;; this is just a catch all that I didn't know where to put.

(import-macros {: mod-invoke} :helpers)

(macro setup-fuzzy-mappings []
  `(do
     (vim.keymap.set :n :<leader>zb #(mod-invoke :fsouza.lib.fuzzy :buffers)
                     {:silent true})
     (vim.keymap.set :n :<leader>zz #(mod-invoke :fsouza.lib.fuzzy :files)
                     {:silent true})
     (vim.keymap.set :n :<leader>zg #(mod-invoke :fsouza.lib.fuzzy :git-files)
                     {:silent true})
     (vim.keymap.set :n :<leader>zt #(mod-invoke :fsouza.lib.fuzzy :tagstack)
                     {:silent true})
     (vim.keymap.set :n :<leader>zp #(mod-invoke :fsouza.lib.fuzzy :git-repos)
                     {:silent true})
     (vim.keymap.set :n "<leader>;" #(mod-invoke :fsouza.lib.fuzzy :commands)
                     {:silent true})
     (vim.keymap.set :n :<leader>gs #(mod-invoke :fsouza.lib.fuzzy :git_status)
                     {:silent true})
     (vim.keymap.set :n :<leader>zh #(mod-invoke :fsouza.lib.fuzzy :help_tags)
                     {:silent true})
     (vim.keymap.set :n :<leader>zo #(mod-invoke :fsouza.lib.fuzzy :quickfix)
                     {:silent true})
     (vim.keymap.set :n :<leader>zr #(mod-invoke :fsouza.lib.fuzzy :resume)
                     {:silent true})
     (vim.keymap.set :n :<leader>zj
                     #(let [dir-path# (vim.fn.expand "%:p:h")]
                        (when (vim.startswith dir-path# "/")
                          (mod-invoke :fsouza.lib.fuzzy :files {:cwd dir-path#})))
                     {:silent true})
     (vim.keymap.set :n :<leader>gg #(mod-invoke :fsouza.lib.fuzzy :live-grep))
     (vim.keymap.set :n :<leader>gw
                     #(mod-invoke :fsouza.lib.fuzzy :grep
                                  (vim.fn.expand :<cword>) :-F))
     (vim.keymap.set :x :<leader>gw
                     #(mod-invoke :fsouza.lib.fuzzy :grep-visual))
     (vim.keymap.set :n :<leader>gl #(mod-invoke :fsouza.lib.fuzzy :grep-last))
     (vim.keymap.set :n :<leader>zl #(mod-invoke :fsouza.lib.fuzzy :lines))))

(macro setup-autofmt-commands []
  `(do
     (vim.api.nvim_create_user_command :ToggleAutofmt
                                       #(mod-invoke :fsouza.lib.autofmt :toggle)
                                       {:force true})
     (vim.api.nvim_create_user_command :ToggleGlobalAutofmt
                                       #(mod-invoke :fsouza.lib.autofmt
                                                    :toggle_g)
                                       {:force true})))

(macro setup-word-replace []
  `(vim.keymap.set :n :<leader>e
                   #(let [word# (vim.fn.expand :<cword>)]
                      (vim.api.nvim_input (.. ":%s/\\v<lt>" word#
                                              :>//g<left><left>)))))

(macro setup-notif []
  `(vim.api.nvim_create_user_command :Notifications
                                     #(mod-invoke :fsouza.lib.notif
                                                  :log-messages)
                                     {:force true}))

(do
  (setup-autofmt-commands)
  (setup-word-replace)
  (setup-notif)
  (setup-fuzzy-mappings))
