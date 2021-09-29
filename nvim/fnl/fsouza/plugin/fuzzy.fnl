(local helpers (require "fsouza.lib.nvim_helpers"))

(fn should-qf [selected]
  (let [n-selected (length selected)
        tablex (require "fsouza.tablex")]
    (if (<= (length selected) 2)
      false
      (tablex.exists
        selected
        (fn [sel]
          (if (string.match sel "^.+:%d+:%d+:")
            true
            false))))))

(fn edit-or-qf [selected]
  (let [actions (require "fzf-lua.actions")]
    (if (should-qf selected)
      (do
        (actions.file_sel_to_qf selected)
        (vim.cmd "cc"))
      (do
        (actions.file_edit selected [])))))

(fn file-actions []
  (let [actions (require "fzf-lua.actions")]
    {:default edit-or-qf
     :ctrl-s actions.file_spit
     :ctrl-v actions.file_vsplit
     :ctrl-t actions.file_tabedit
     :ctrl-q actions.file_sel_to_qf}))

(local fzf-lua
  (helpers.once
    (fn []
      (vim.cmd "packadd nvim-fzf")

      (let [actions (file-actions)
            fzf-lua- (require "fzf-lua")]
        (fzf-lua-.setup {:fzf_args vim.env.FZF_DEFAULT_OPTS
                         :fzf_layout "default"
                         :fzf_binds ["alt-a:toggle-all"
                                     "ctrl-l:clear-query"
                                     "ctrl-d:preview-half-page-down"
                                     "ctrl-u:preview-half-page-up"
                                     "ctrl-h:toggle-preview"]
                         :buffers {:file_icons false
                                   :git_icons false}
                         :files {:file_icons false
                                 :git_icons false
                                 :actions actions}
                         :git {:file_icons false
                               :git_icons false
                               :actions actions}
                         :grep {:file_icons false
                                :git_icons false
                                :actions actions}
                         :oldfiles {:file_icons false
                                    :git_icons false
                                    :actions actions}
                         :lsp {:file_icons false
                               :git_icons false
                               :actions actions}
                         :winopts {:win_height 0.75
                                   :win_width 0.90}
                         :previewers {:builtin {:keymap {:toggle_hide "<c-h>"
                                                         :toggle_full "<c-o>"
                                                         :page_up "<c-u>"
                                                         :page_down "<c-d>"
                                                         :page_reset "<c-r>"}}}})

        fzf-lua-))))

(fn grep [rg-opts search]
  (let [search (helpers.if-nil search (partial vim.fn.input "rg："))
        fzf-lua (fzf-lua)]
    (when (not= search "")
      (fzf-lua.grep {:search search
                     :raw_cmd (string.format "rg %s -- %s" rg-opts (vim.fn.shellescape search))}))))

(fn send-items [items prompt]
  (let [prompt (.. prompt "：")
        fzf-lua (fzf-lua)
        config (require "fzf-lua.config")
        core (require "fzf-lua.core")
        opts (config.normalize_opts {:prompt prompt :cwd (vim.fn.getcwd)} config.globals.lsp)]
    (tset opts :fzf_fn
          (icollect [_ item (ipairs items)]
            (let [item (core.make_entry_lcol opts item)]
              (core.make_entry_file opts item))))
    (fzf-lua.fzf_files (core.set_fzf_line_args opts))))

(fn grep-visual [rg-opts]
  (let [fzf-lua (fzf-lua)]
    (fzf-lua.grep_visual {:rg_opts rg-opts})))

(let [rg-opts "--column -n --hidden --no-heading --color=always -S --glob '!.git' --glob '!.hg'"
      mod {:find-files (fn [dir]
                         (let [fzf-lua (fzf-lua)]
                           (fzf-lua.files {:cwd dir})))
           :grep (partial grep rg-opts)
           :grep-visual (partial grep-visual rg-opts)
           :send-items send-items}]
  (setmetatable mod
                {:__index (fn [table key]
                            (let [fzf-lua (fzf-lua)
                                  value (. fzf-lua key)]
                              (rawset table key value)
                              value))}))
