;; this is just a catch all that I didn't know where to put.

(import-macros {: mod-invoke} :helpers)

(macro invoke-here [op]
  `(let [dir-path# (vim.fn.expand "%:p:h")]
     (when (vim.startswith dir-path# "/")
       (mod-invoke :fsouza.lib.fuzzy ,op {:cwd dir-path#}))))

(macro setup-fuzzy-mappings []
  `(do
     (vim.keymap.set :n :<leader>zb #(mod-invoke :fsouza.lib.fuzzy :buffers)
                     {:silent true})
     (vim.keymap.set :n :<leader>zz #(mod-invoke :fsouza.lib.fuzzy :files)
                     {:silent true})
     (vim.keymap.set :n :<leader>zg #(mod-invoke :fsouza.lib.fuzzy :git-files)
                     {:silent true})
     (vim.keymap.set :n :<leader>zi #(mod-invoke :fsouza.lib.fuzzy :oldfiles)
                     {:silent true})
     (vim.keymap.set :n :<leader>zt #(mod-invoke :fsouza.lib.fuzzy :tagstack)
                     {:silent true})
     (vim.keymap.set :n :<leader>zp #(mod-invoke :fsouza.lib.fuzzy :git-repos)
                     {:silent true})
     (vim.keymap.set :n :<leader>gs #(mod-invoke :fsouza.lib.fuzzy :git_status)
                     {:silent true})
     (vim.keymap.set :n :<leader>zh #(mod-invoke :fsouza.lib.fuzzy :help_tags)
                     {:silent true})
     (vim.keymap.set :n :<leader>zo #(mod-invoke :fsouza.lib.fuzzy :quickfix)
                     {:silent true})
     (vim.keymap.set :n :<leader>zr #(mod-invoke :fsouza.lib.fuzzy :resume)
                     {:silent true})
     (vim.keymap.set :n :<leader>zj #(invoke-here :files) {:silent true})
     (vim.keymap.set :n :<leader>gg #(mod-invoke :fsouza.lib.fuzzy :live-grep))
     (vim.keymap.set :n :<leader>gj #(invoke-here :live-grep))
     (vim.keymap.set :n :<leader>gw
                     #(mod-invoke :fsouza.lib.fuzzy :grep
                                  (vim.fn.expand :<cword>) :-F))
     (vim.keymap.set :x :<leader>gw
                     #(mod-invoke :fsouza.lib.fuzzy :grep-visual))
     (vim.keymap.set :n :<leader>gl #(mod-invoke :fsouza.lib.fuzzy :grep-last))
     (vim.keymap.set :n :<leader><leader>gg
                     #(mod-invoke :fsouza.lib.fuzzy :live-grep
                                  {:cwd (vim.uv.cwd)}))
     (vim.keymap.set :n :<leader><leader>gw
                     #(mod-invoke :fsouza.lib.fuzzy :grep
                                  (vim.fn.expand :<cword>) :-F (vim.uv.cwd)))
     (vim.keymap.set :x :<leader><leader>gw
                     #(mod-invoke :fsouza.lib.fuzzy :grep-visual (vim.uv.cwd)))
     (vim.keymap.set :n :<leader>zl #(mod-invoke :fsouza.lib.fuzzy :lines))
     (vim.keymap.set :n :<leader>zc
                     #(mod-invoke :fsouza.lib.fuzzy :set-virtual-cwd)
                     {:silent true})
     (vim.api.nvim_create_user_command :Fcd
                                       #(let [{:fargs fargs#} $1]
                                          (mod-invoke :fsouza.lib.fuzzy
                                                      :set-virtual-cwd
                                                      (. fargs# 1)))
                                       {:force true :complete :dir :nargs "?"})))

(macro setup-autofmt-commands []
  `(do
     (vim.api.nvim_create_user_command :ToggleAutofmt
                                       #(mod-invoke :fsouza.lib.autofmt :toggle)
                                       {:force true})
     (vim.api.nvim_create_user_command :ToggleGlobalAutofmt
                                       #(mod-invoke :fsouza.lib.autofmt
                                                    :toggle_g)
                                       {:force true})))

(macro setup-browse-command []
  `(vim.api.nvim_create_user_command :OpenBrowser
                                     #(let [{:fargs [url#]} $1]
                                        (vim.ui.open url#))
                                     {:force true :nargs 1}))

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
  (setup-browse-command)
  (setup-word-replace)
  (setup-notif)
  (setup-fuzzy-mappings))
