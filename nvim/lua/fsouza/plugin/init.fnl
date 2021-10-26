(import-macros {: vim-schedule} :helpers)

(local helpers (require :fsouza.lib.nvim-helpers))

(fn fuzzy [member ...]
  (let [mod (require :fsouza.plugin.fuzzy)
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
                                                   (let [vhl (require :vim.highlight)]
                                                     (vhl.on_yank {:higroup "HlYank"
                                                                   :timeout 200
                                                                   :on_macro false}))))}]))

(fn setup-word-replace []
  (helpers.create-mappings {:n [{:lhs "<leader>e"
                                 :rhs (helpers.fn-map
                                        (fn []
                                          (let [word-sub (require :fsouza.plugin.word-sub)]
                                            (word-sub.run))))}]}))


(fn setup-spell []
  (helpers.augroup "fsouza__auto_spell" [{:events ["FileType"]
                                          :targets ["changelog" "gitcommit" "markdown" "text"]
                                          :command "setlocal spell"}]))

(fn setup-editorconfig []
  (let [editorconfig (require :fsouza.plugin.editorconfig)]
    (editorconfig.enable))
  (vim-schedule
    (do
      (vim.cmd "command! EnableEditorConfig lua require('fsouza.plugin.editorconfig').enable()")
      (vim.cmd "command! DisableEditorConfig lua require('fsouza.plugin.editorconfig').disable()"))))

(fn setup-shortcuts []
  (let [shortcut (require :fsouza.plugin.shortcut)]
    (shortcut.register "Dotfiles" (vim.fn.expand "~/.dotfiles"))))

(fn setup-terminal-mappings []
  (fn term-open [term]
    (let [mod (require :fsouza.plugin.terminal)]
      (mod.open term)))

  (macro term-mapping [term-id modifier]
    `{:lhs ,(.. "<c-t>" term-id)
      :rhs (helpers.fn-map (partial term-open ,term-id))
      :opts {:silent true}})

  (helpers.create-mappings {:n [(term-mapping "j")
                                (term-mapping "k")
                                (term-mapping "l")]}))

(fn setup-autocompile []
  (fn handle-result [next result]
    (if (= result.exit-status 0)
      (do
        (vim.notify "Successfully compiled")
        (when next
          (next)))
      (error (string.format "failed to compile fnl: %s" (vim.inspect result)))))

  (fn repaq []
    (let [packed (require :fsouza.packed)]
      (packed.repack)))

  (fn make []
    (when (not vim.g.fennel_ks)
      (let [cmd (require :fsouza.lib.cmd)
            file-name (vim.fn.expand "<afile>")
            make-target "install-site"
            next (if (vim.endswith file-name "/packed.fnl")
                   repaq
                   nil)]

        (cmd.run "make" {:args ["-C" config-dir make-target]} nil (partial handle-result next)))))

  (helpers.augroup "fsouza__autocompile-fennel" [{:events ["BufWritePost"]
                                                  :targets ["~/.dotfiles/nvim/*.fnl"]
                                                  :command (helpers.fn-cmd make)}]))

(macro mod-invoke [mod fn-name ...]
  `(let [mod# (require ,mod)
         f# (. mod# ,fn-name)]
     (f# ,...)))

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
  (vim-schedule (mod-invoke :colorizer :setup [:css :fennel :javascript :html :lua :htmldjango :yaml]))
  (schedule setup-terminal-mappings)
  (vim-schedule (require :fsouza.lsp))
  (vim-schedule (require :fsouza.plugin.ts))
  (schedule setup-lsp-commands)
  (schedule setup-fuzzy-mappings)
  (schedule setup-autocompile)
  (vim-schedule (vim.cmd "doautoall FileType"))
  (vim-schedule (vim.cmd "doautocmd User PluginReady")))
