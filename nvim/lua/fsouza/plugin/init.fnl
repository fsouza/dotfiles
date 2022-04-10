(import-macros {: vim-schedule : mod-invoke} :helpers)

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
  (vim.keymap.set :n :<leader>zj
                  #(let [dir-path (vim.fn.expand "%:p:h")]
                     (when (vim.startswith dir-path "/")
                       (mod-invoke :fsouza.plugin.fuzzy :find-files dir-path)))
                  {:silent true})
  (vim.keymap.set :n :<leader>gg #(mod-invoke :fsouza.plugin.fuzzy :grep))
  (vim.keymap.set :n :<leader>gw
                  #(mod-invoke :fsouza.plugin.fuzzy :grep
                               (vim.fn.expand :<cword>)))
  (vim.keymap.set :x :<leader>gw
                  #(mod-invoke :fsouza.plugin.fuzzy :grep-visual)))

(fn setup-git-messenger []
  (let [load-git-messenger (helpers.once #(vim.cmd "packadd git-messenger.vim"))]
    (vim.keymap.set :n :<leader>gm
                    #(do
                       (load-git-messenger)
                       (vim.cmd :GitMessenger)))))

(fn setup-autofmt-commands []
  (vim.api.nvim_add_user_command :ToggleAutofmt
                                 "lua require('fsouza.lib.autofmt').toggle()"
                                 {:force true})
  (vim.api.nvim_add_user_command :ToggleGlobalAutofmt
                                 "lua require('fsouza.lib.autofmt').toggle_g()"
                                 {:force true}))

(fn setup-lsp-commands []
  (vim.api.nvim_add_user_command :LspRestart
                                 "lua require('fsouza.lsp.detach').restart()"
                                 {:force true}))

(fn setup-lsp []
  (fn do-setup []
    (require :fsouza.lsp)
    (setup-lsp-commands))

  (if (= (vim.loop.cwd) (vim.loop.os_homedir))
      (helpers.augroup :fsouza-lsp-change-dir-setup
                       [{:events [:DirChanged]
                         :targets ["*"]
                         :callback do-setup
                         :once true}])
      (do-setup)))

(fn setup-hlyank []
  (helpers.augroup :yank_highlight
                   [{:events [:TextYankPost]
                     :targets ["*"]
                     :callback #(mod-invoke :vim.highlight :on_yank
                                            {:higroup :HlYank
                                             :timeout 200
                                             :on_macro false})}]))

(fn setup-word-replace []
  (vim.keymap.set :n :<leader>e #(mod-invoke :fsouza.plugin.word-sub :run)))

(fn setup-spell []
  (helpers.augroup :fsouza__auto_spell
                   [{:events [:FileType]
                     :targets [:changelog :gitcommit :markdown :text]
                     :command "setlocal spell"}]))

(fn setup-editorconfig []
  (mod-invoke :fsouza.plugin.editorconfig :enable)
  (vim-schedule (vim.api.nvim_add_user_command :EnableEditorConfig
                                               "lua require('fsouza.plugin.editorconfig').enable()"
                                               {:force true})
                (vim.api.nvim_add_user_command :DisableEditorConfig
                                               "lua require('fsouza.plugin.editorconfig').disable()"
                                               {:force true})))

(fn setup-shortcuts []
  (let [shortcut (require :fsouza.plugin.shortcut)
        path (require :pl.path)]
    (shortcut.register :Dotfiles (vim.fn.expand "~/.dotfiles"))
    (shortcut.register :Site (path.join data-dir :site))))

(fn setup-notif []
  (vim.api.nvim_add_user_command :Notifications
                                 "lua require('fsouza.lib.notif')['log-messages']()"
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

(let [schedule vim.schedule]
  (vim-schedule (mod-invoke :fsouza.lib.cleanup :setup))
  (schedule setup-editorconfig)
  (schedule setup-git-messenger)
  (schedule setup-hlyank)
  (vim-schedule (mod-invoke :fsouza.plugin.mkdir :setup))
  (schedule setup-autofmt-commands)
  (schedule setup-word-replace)
  (schedule setup-spell)
  (schedule setup-shortcuts)
  (schedule setup-notif)
  (vim-schedule (mod-invoke :colorizer :setup
                            [:css
                             :fennel
                             :javascript
                             :html
                             :lua
                             :htmldjango
                             :yaml]))
  (schedule setup-terminal-mappings)
  (schedule setup-lsp)
  (vim-schedule (require :fsouza.plugin.ts))
  (vim-schedule (require :fsouza.plugin.fidget))
  (vim-schedule (mod-invoke :fsouza.plugin.rg-complete :setup :<c-x><c-n>))
  (schedule setup-comment-nvim)
  (schedule setup-fuzzy-mappings)
  (vim-schedule (mod-invoke :fsouza.plugin.fnl-autocompile :setup))
  (vim-schedule (vim.api.nvim_exec_autocmds [:FileType] {}))
  (vim-schedule (vim.api.nvim_exec_autocmds [:User] {:pattern :PluginReady})))
