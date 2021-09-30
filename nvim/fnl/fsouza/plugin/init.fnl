(local helpers (require "fsouza.lib.nvim_helpers"))

(fn fuzzy [member ...]
  (let [mod (require "fsouza.plugin.fuzzy")
        f (. mod member)]
    (f ...)))

(fn setup-fuzzy-mappings []
  (helpers.create-mappings {:n [{:lhs "<leader>zb"
                                 :rhs (helpers.fn-map (partial fuzzy "buffers"))
                                 :opts {:silent true}}
                                {:lhs "<leader>zz"
                                 :rhs (helpers.fn-map (partial fuzzy "find-files"))
                                 :opts {:silent true}}
                                {:lhs "<leader>;"
                                 :rhs (helpers.fn-map (partial fuzzy "commands"))
                                 :opts {:silent true}}
                                {:lhs "<leader>zj"
                                 :rhs (helpers.fn-map (fn []
                                                        (let [dir-path (vim.fn.expand "%:p:h")]
                                                          (when (vim.startswith dir-path "/")
                                                            (fuzzy "find-files" dir-path)))))
                                 :opts {:silent true}}
                                {:lhs "<leader>gg"
                                 :rhs (helpers.fn-map (partial fuzzy "grep"))
                                 :opts {:silent true}}
                                {:lhs "<leader>gw"
                                 :rhs (helpers.fn-map (fn []
                                                        (fuzzy "grep" (vim.fn.expand "<cword>"))))
                                 :opts {:silent true}}]
                            :v [{:lhs "<leader>gw"
                                 :rhs (helpers.fn-map (partial fuzzy "grep-visual"))
                                 :opts {:silent true}}]}))

(fn setup-git-messenger []
  (let [load-git-messenger (helpers.once (partial vim.cmd "packadd git-messenger.vim"))]
    (helpers.create-mappings {:n [{:lhs "<leader>gm"
                                   :rhs (helpers.fn-map
                                          (fn []
                                            (load-git-messenger)
                                            (vim.cmd "GitMessenger")))}]})))

(fn setup-autofmt-commands []
  (vim.cmd "command! ToggleAutofmt lua require('fsouza.lib.autofmt').toggle()")
  (vim.cmd "command! ToggleGlobalAutofmt lua require('fsouza.lib.autofmt').toggle_g()"))

(fn setup-lsp-commands []
  (vim.cmd "command! LspRestart lua require('fsouza.lsp.detach').restart()"))

(fn setup-hlyank []
  (helpers.augroup "yank_highlight" [{:events ["TextYankPost"]
                                      :targets ["*"]
                                      :command (helpers.fn-cmd
                                                 (fn []
                                                   (let [vhl (require "vim.highlight")]
                                                     (vhl.on_yank {:higroup "HlYank"
                                                                   :timeout 200
                                                                   :on_macro false}))))}]))

(fn setup-word-replace []
  (helpers.create-mappings {:n [{:lhs "<leader>e"
                                 :rhs (helpers.fn-map
                                        (fn []
                                          (let [word-sub (require "fsouza.plugin.word_sub")]
                                            (word-sub.run))))}]}))


(fn setup-spell []
  (helpers.augroup "fsouza__auto_spell" [{:events ["FileType"]
                                          :targets ["changelog" "gitcommit" "markdown" "text"]
                                          :command "setlocal spell"}]))

(fn setup-editorconfig []
  (let [editorconfig (require "fsouza.plugin.editorconfig")]
    (editorconfig.enable))
  (vim.schedule
    (fn []
      (vim.cmd "command! EnableEditorConfig lua require('fsouza.plugin.editorconfig').enable()")
      (vim.cmd "command! DisableEditorConfig lua require('fsouza.plugin.editorconfig').disable()"))))

(fn setup-shortcuts []
  (let [shortcut (require "fsouza.plugin.shortcut")]
    (shortcut.register "Dotfiles" (vim.fn.expand "~/.dotfiles"))))

(fn term-open [term]
  (let [mod (require "fsouza.plugin.terminal")]
    (mod.open term)))

(fn setup-terminal-mappings []
  (helpers.create-mappings {:n [{:lhs "<c-t>j"
                                 :rhs (helpers.fn-map (partial term-open "j"))
                                 :opts {:silent true}}
                                {:lhs "<c-t>k"
                                 :rhs (helpers.fn-map (partial term-open "k"))
                                 :opts {:silent true}}
                                {:lhs "<c-t>l"
                                 :rhs (helpers.fn-map (partial term-open "l"))
                                 :opts {:silent true}}]}))

;; helper function to import a module and invoke a function.
(fn mod-invoke [mod fn-name ...]
  (let [mod (require mod)
        f (. mod fn-name)]
    (f ...)))

(do
  (let [schedule vim.schedule]
    (schedule (partial mod-invoke "fsouza.lib.cleanup" "setup"))
    (schedule setup-editorconfig)
    (schedule setup-git-messenger)
    (schedule setup-hlyank)
    (schedule (partial mod-invoke "fsouza.plugin.mkdir" "setup"))
    (schedule setup-autofmt-commands)
    (schedule setup-word-replace)
    (schedule setup-spell)
    (schedule setup-shortcuts)
    (schedule (partial mod-invoke "colorizer" "setup" ["css" "fennel" "javascript" "html" "lua" "htmldjango" "yaml"]))
    (schedule setup-terminal-mappings)
    (schedule (partial require "fsouza.lsp"))
    ; (schedule (partial require "fsouza.plugin.ts"))
    (schedule setup-lsp-commands)
    (schedule setup-fuzzy-mappings)
    (schedule (partial vim.cmd "doautoall FileType"))
    (schedule (partial vim.cmd "doautocmd User PluginReady"))))
