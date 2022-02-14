(import-macros {: if-nil} :helpers)

(local helpers (require :fsouza.lib.nvim-helpers))

(fn should-qf [selected]
  (let [n-selected (length selected)
        tablex (require :fsouza.tablex)]
    (if (<= (length selected) 1) false
        (tablex.exists selected #(if (string.match $1 "^.+:%d+:%d+:") true
                                     false)))))

(fn edit [selected]
  (let [fzf-path (require :fzf-lua.path)]
    (each [_ sel (ipairs selected)]
      (let [entry (fzf-path.entry_to_file sel)]
        (vim.cmd (string.format "edit %s" (vim.fn.fnameescape entry.path)))
        (vim.api.nvim_win_set_cursor 0 [entry.line (- entry.col 1)])))))

(fn edit-or-qf [selected]
  (let [actions (require :fzf-lua.actions)]
    (if (should-qf selected)
        (do
          (actions.file_sel_to_qf selected)
          (vim.cmd :cc))
        (edit selected))))

(fn file-actions []
  (let [actions (require :fzf-lua.actions)]
    {:default edit-or-qf
     :ctrl-s actions.file_spit
     :ctrl-v actions.file_vsplit
     :ctrl-t actions.file_tabedit
     :ctrl-q actions.file_sel_to_qf}))

(local fzf-lua (helpers.once (fn []
                               (vim.cmd "packadd nvim-fzf")
                               (let [actions (file-actions)
                                     fzf-lua- (require :fzf-lua)]
                                 (fzf-lua-.setup {:fzf_args vim.env.FZF_DEFAULT_OPTS
                                                  :fzf_layout :default
                                                  :buffers {:file_icons false
                                                            :git_icons false}
                                                  :files {:file_icons false
                                                          :git_icons false
                                                          : actions}
                                                  :git {:file_icons false
                                                        :git_icons false
                                                        : actions}
                                                  :grep {:file_icons false
                                                         :git_icons false
                                                         : actions}
                                                  :oldfiles {:file_icons false
                                                             :git_icons false
                                                             : actions}
                                                  :lsp {:file_icons false
                                                        :git_icons false
                                                        : actions}
                                                  :winopts {:win_height 0.75
                                                            :win_width 0.9}
                                                  :keymap {:builtin {:<c-h> :toggle-preview
                                                                     :<c-u> :preview-page-up
                                                                     :<c-d> :preview-page-down
                                                                     :<c-r> :preview-page-reset}}
                                                  :fzf {:alt-a :toggle-all
                                                        :ctrl-l :clear-query
                                                        :ctrl-d :preview-half-page-down
                                                        :ctrl-u :preview-half-page-up
                                                        :ctrl-h :toggle-preview}})
                                 fzf-lua-))))

(fn grep [rg-opts search]
  (let [search (if-nil search (vim.fn.input "rg："))
        fzf-lua (fzf-lua)]
    (when (not= search "")
      (fzf-lua.grep {: search
                     :raw_cmd (string.format "rg %s -- %s" rg-opts
                                             (vim.fn.shellescape search))}))))

(fn send-items [items prompt]
  (let [prompt (.. prompt "：")
        fzf-lua (fzf-lua)
        config (require :fzf-lua.config)
        core (require :fzf-lua.core)
        opts (config.normalize_opts {: prompt :cwd (vim.fn.getcwd)}
                                    config.globals.lsp)]
    (tset opts :fzf_fn
          (icollect [_ item (ipairs items)]
            (let [item (core.make_entry_lcol opts item)]
              (core.make_entry_file opts item))))
    (core.fzf_files (core.set_fzf_field_index opts))))

(fn grep-visual [rg-opts]
  (let [fzf-lua (fzf-lua)]
    (fzf-lua.grep_visual {:rg_opts rg-opts})))

(let [rg-opts "--column -n --hidden --no-heading --color=always -S --glob '!.git' --glob '!.hg'"
      mod {:find-files #(let [fzf-lua (fzf-lua)]
                          (fzf-lua.files {:cwd $1}))
           :grep (partial grep rg-opts)
           :grep-visual (partial grep-visual rg-opts)
           : send-items}]
  (setmetatable mod {:__index (fn [table key]
                                (let [fzf-lua (fzf-lua)
                                      value (. fzf-lua key)]
                                  (rawset table key value)
                                  value))}))
