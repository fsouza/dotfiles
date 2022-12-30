(import-macros {: mod-invoke} :helpers)

(local helpers (require :fsouza.lib.nvim-helpers))

(fn setup-fuzzy-mappings []
  (vim.keymap.set :n :<leader>zb #(mod-invoke :fsouza.plugin.fuzzy :buffers)
                  {:silent true})
  (vim.keymap.set :n :<leader>zz #(mod-invoke :fsouza.plugin.fuzzy :find-files)
                  {:silent true})
  (vim.keymap.set :n :<leader>zt #(mod-invoke :fsouza.plugin.fuzzy :tagstack)
                  {:silent true})
  (vim.keymap.set :n :<leader>zp #(mod-invoke :fsouza.plugin.fuzzy :git-repos)
                  {:silent true})
  (vim.keymap.set :n "<leader>;" #(mod-invoke :fsouza.plugin.fuzzy :commands)
                  {:silent true})
  (vim.keymap.set :n :<leader>gs #(mod-invoke :fsouza.plugin.fuzzy :git_status)
                  {:silent true})
  (vim.keymap.set :n :<leader>zh #(mod-invoke :fsouza.plugin.fuzzy :help_tags)
                  {:silent true})
  (vim.keymap.set :n :<leader>zo #(mod-invoke :fsouza.plugin.fuzzy :quickfix)
                  {:silent true})
  (vim.keymap.set :n :<leader>zr #(mod-invoke :fsouza.plugin.fuzzy :resume)
                  {:silent true})
  (vim.keymap.set :n :<leader>zj
                  #(let [dir-path (vim.fn.expand "%:p:h")]
                     (when (vim.startswith dir-path "/")
                       (mod-invoke :fsouza.plugin.fuzzy :find-files dir-path)))
                  {:silent true})
  (vim.keymap.set :n :<leader>gg #(mod-invoke :fsouza.plugin.fuzzy :live-grep))
  (vim.keymap.set :n :<leader>gw
                  #(mod-invoke :fsouza.plugin.fuzzy :grep
                               (vim.fn.expand :<cword>)))
  (vim.keymap.set :x :<leader>gw
                  #(mod-invoke :fsouza.plugin.fuzzy :grep-visual))
  (vim.keymap.set :n :<leader>gl #(mod-invoke :fsouza.plugin.fuzzy :grep_last))
  (vim.keymap.set :n :<leader>zl #(mod-invoke :fsouza.plugin.fuzzy :lines)))

(fn setup-git-messenger []
  (let [load-git-messenger (helpers.once #(vim.cmd.packadd :git-messenger.vim))]
    (vim.keymap.set :n :<leader>gm
                    #(do
                       (load-git-messenger)
                       (vim.cmd.GitMessenger)))))

(fn setup-autofmt-commands []
  (vim.api.nvim_create_user_command :ToggleAutofmt
                                    #(mod-invoke :fsouza.lib.autofmt :toggle)
                                    {:force true})
  (vim.api.nvim_create_user_command :ToggleGlobalAutofmt
                                    #(mod-invoke :fsouza.lib.autofmt :toggle_g)
                                    {:force true}))

(fn setup-lsp-commands []
  (vim.api.nvim_create_user_command :LspRestart
                                    #(mod-invoke :fsouza.lsp.detach :restart)
                                    {:force true})
  (vim.api.nvim_create_user_command :LspSync
                                    #(mod-invoke :fsouza.lsp.sync
                                                 :sync-all-buffers)
                                    {:force true}))

(fn setup-lsp []
  (mod-invoke :fsouza.lsp :setup)
  (setup-lsp-commands))

(fn setup-hlyank []
  (helpers.augroup :yank_highlight
                   [{:events [:TextYankPost]
                     :targets ["*"]
                     :callback #(mod-invoke :vim.highlight :on_yank
                                            {:higroup :HlYank
                                             :timeout 200
                                             :on_macro false})}]))

(fn setup-word-replace []
  (vim.keymap.set :n :<leader>e
                  #(let [word (vim.fn.expand :<cword>)]
                     (vim.api.nvim_input (.. ":%s/\\v<lt>" word
                                             :>//g<left><left>)))))

(fn setup-spell []
  (helpers.augroup :fsouza__auto_spell
                   [{:events [:FileType]
                     :targets [:changelog :gitcommit :help :markdown :text]
                     :command "setlocal spell"}]))

(fn setup-vim-notify []
  (let [tablex (require :fsouza.pl.tablex)
        patterns ["message with no corresponding"]
        orig-notify vim.notify]
    (fn notify [msg level opts]
      (when (tablex.for-all patterns #(= (string.find msg $1) nil))
        (orig-notify msg level opts)))

    (tset vim :notify notify)))

(fn setup-editorconfig []
  (mod-invoke :fsouza.plugin.editorconfig :enable)
  (vim.api.nvim_create_user_command :EnableEditorConfig
                                    #(mod-invoke :fsouza.plugin.editorconfig
                                                 :enable)
                                    {:force true})
  (vim.api.nvim_create_user_command :DisableEditorConfig
                                    #(mod-invoke :fsouza.plugin.editorconfig
                                                 :disable)
                                    {:force true}))

(fn setup-shortcuts []
  (let [shortcut (require :fsouza.plugin.shortcut)
        path (require :fsouza.pl.path)]
    (shortcut.register :Dotfiles dotfiles-dir)
    (shortcut.register :Site (path.join data-dir :site))))

(fn setup-notif []
  (vim.api.nvim_create_user_command :Notifications
                                    #(mod-invoke :fsouza.lib.notif
                                                 :log-messages)
                                    {:force true}))

(fn setup-terminal-mappings []
  (fn term-open [term-id]
    (mod-invoke :fsouza.plugin.terminal :open term-id))

  (macro term-mapping [term-id]
    `(vim.keymap.set :n ,(.. :<a-t> term-id) #(term-open ,term-id)))
  (term-mapping :j)
  (term-mapping :k)
  (term-mapping :l))

(fn setup-comment-nvim []
  (fn pre-hook [ctx]
    (let [U (require :Comment.utils)
          tcs-utils (require :ts_context_commentstring.utils)
          location (if (= ctx.ctype U.ctype.block)
                       (tcs-utils.get_cursor_location)
                       (or (= ctx.cmotion U.cmotion.v)
                           (= ctx.cmotion U.cmotion.V))
                       (tcs-utils.get_visual_start_location)
                       nil)
          key (if (= ctx.ctype U.ctype.line) :__default :__multiline)
          tcs-internal (require :ts_context_commentstring.internal)]
      (tcs-internal.calculate_commentstring {: key : location})))

  (mod-invoke :Comment :setup {:pre_hook pre-hook :ignore #"^$"}))

(fn setup-completion []
  (fn cr-key-for-comp-info [comp-info]
    (if (= comp-info.mode "") :<cr>
        (if (and (= comp-info.pum_visible 1) (= comp-info.selected -1))
            :<c-e><cr> :<cr>)))

  (fn process-items [items base]
    (let [mini-completion (require :mini.completion)
          tablex (require :fsouza.pl.tablex)]
      (-> items
          (mini-completion.default_process_items base)
          (tablex.filter #(not= (. $1 :kind) 14)))))

  (vim.keymap.set :i :<cr> #(cr-key-for-comp-info (vim.fn.complete_info))
                  {:remap false :expr true})
  (mod-invoke :mini.completion :setup
              {:delay {:completion 100 :info 0 :signature 0}
               :lsp_completion {:process_items process-items}
               :set_vim_settings false}))

(fn setup-treesitter []
  (when (not vim.env.NVIM_SKIP_TREESITTER)
    (mod-invoke :fsouza.plugin.ts :setup)))

(macro setup-delayed-commands []
  (let [commands [:LspRestart
                  :LspSync
                  :EnableEditorConfig
                  :DisableEditorConfig
                  :ToggleAutofmt
                  :ToggleGlobalAutofmt
                  :Dotfiles
                  :Site]]
    `(let [delayed-commands# (require :fsouza.plugin.delayed-commands)]
       ,(icollect [_ command (ipairs commands)]
          `(delayed-commands#.add ,command)))))

(let [schedule vim.schedule]
  (setup-delayed-commands)
  (schedule setup-vim-notify)
  (schedule setup-editorconfig)
  (schedule setup-git-messenger)
  (schedule setup-hlyank)
  (schedule #(mod-invoke :fsouza.plugin.mkdir :setup))
  (schedule setup-autofmt-commands)
  (schedule setup-word-replace)
  (schedule setup-spell)
  (schedule setup-shortcuts)
  (schedule setup-notif)
  (schedule #(mod-invoke :colorizer :setup
                         [:css
                          :fennel
                          :javascript
                          :html
                          :lua
                          :htmldjango
                          :tmux
                          :yaml]))
  (schedule setup-terminal-mappings)
  (schedule setup-lsp)
  (schedule setup-treesitter)
  (schedule #(mod-invoke :fsouza.plugin.fidget :setup))
  (schedule #(mod-invoke :fsouza.plugin.rg-complete :setup :<c-x><c-n>))
  (schedule #(mod-invoke :fsouza.plugin.auto-delete :setup))
  (schedule setup-comment-nvim)
  (schedule setup-completion)
  (schedule setup-fuzzy-mappings)
  (schedule #(mod-invoke :fsouza.plugin.fnl-autocompile :setup))
  (schedule #(vim.api.nvim_exec_autocmds [:User] {:pattern :PluginReady})))
