;; this is just a catch all that I didn't know where to put.

(macro invoke-here [op]
  `(let [dir-path# (vim.fn.expand "%:p:h")]
     (when (vim.startswith dir-path# "/")
       (,op {:cwd dir-path#}))))

(macro setup-fuzzy-mappings []
  `(let [fuzzy# (require :fsouza.lib.fuzzy)]
     (vim.keymap.set :n :<leader>zb #(fuzzy#.buffers) {:silent true})
     (vim.keymap.set :n :<leader>zz #(fuzzy#.files) {:silent true})
     (vim.keymap.set :n :<leader>zg #(fuzzy#.git-files) {:silent true})
     (vim.keymap.set :n :<leader>zi #(fuzzy#.oldfiles) {:silent true})
     (vim.keymap.set :n :<leader>zt #(fuzzy#.tagstack) {:silent true})
     (vim.keymap.set :n :<leader>zp #(fuzzy#.git-repos) {:silent true})
     (vim.keymap.set :n :<leader>gs #(fuzzy#.git_status) {:silent true})
     (vim.keymap.set :n :<leader>zh #(fuzzy#.help_tags) {:silent true})
     (vim.keymap.set :n :<leader>zo #(fuzzy#.quickfix) {:silent true})
     (vim.keymap.set :n :<leader>zr #(fuzzy#.resume) {:silent true})
     (vim.keymap.set :n :<leader>zj #(invoke-here fuzzy#.files) {:silent true})
     (vim.keymap.set :n :<leader>gg #(fuzzy#.live-grep))
     (vim.keymap.set :n :<leader>gj #(invoke-here fuzzy#.live-grep))
     (vim.keymap.set :n :<leader>gw #(fuzzy#.grep (vim.fn.expand :<cword>) :-F))
     (vim.keymap.set :x :<leader>gw #(fuzzy#.grep-visual))
     (vim.keymap.set :n :<leader>gl #(fuzzy#.grep-last))
     (vim.keymap.set :n :<leader><leader>gg
                     #(fuzzy#.live-grep {:cwd (vim.uv.cwd)}))
     (vim.keymap.set :n :<leader><leader>gw
                     #(fuzzy#.grep (vim.fn.expand :<cword>) :-F (vim.uv.cwd)))
     (vim.keymap.set :x :<leader><leader>gw #(fuzzy#.grep-visual (vim.uv.cwd)))
     (vim.keymap.set :n :<leader>zl #(fuzzy#.lines))
     (vim.keymap.set :n :<leader>zc #(fuzzy#.set-virtual-cwd) {:silent true})
     (vim.api.nvim_create_user_command :Fcd
                                       #(let [{:fargs fargs#} $1]
                                          (fuzzy#.set-virtual-cwd (. fargs# 1)))
                                       {:force true :complete :dir :nargs "?"})))

(macro setup-autofmt-commands []
  `(let [autofmt# (require :fsouza.lib.autofmt)]
     (vim.api.nvim_create_user_command :ToggleAutofmt #(autofmt#.toggle)
                                       {:force true})
     (vim.api.nvim_create_user_command :ToggleGlobalAutofmt
                                       #(autofmt#.toggle_g) {:force true})))

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
  `(let [notif# (require :fsouza.lib.notif)]
     (vim.api.nvim_create_user_command :Notifications #(notif#.log-messages)
                                       {:force true})))

(do
  (setup-autofmt-commands)
  (setup-browse-command)
  (setup-word-replace)
  (setup-notif)
  (setup-fuzzy-mappings))
