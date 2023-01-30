(import-macros {: mod-invoke} :helpers)

(fn should-qf [selected]
  (let [n-selected (length selected)]
    (if (<= (length selected) 1)
        false
        (mod-invoke :fsouza.pl.tablex :exists selected
                    #(if (string.match $1 "^.+:%d+:%d+:") true false)))))

(fn edit-or-qf [edit selected opts]
  (if (should-qf selected)
      (do
        (mod-invoke :fzf-lua.actions :file_sel_to_qf selected opts)
        (vim.cmd.cc))
      (edit selected opts)))

(fn edit [command selected opts]
  (let [fzf-path (require :fzf-lua.path)
        pl-path (require :fsouza.pl.path)]
    (each [_ sel (ipairs selected)]
      (let [{: path : line : col} (fzf-path.entry_to_file sel opts)
            path (pl-path.relpath path)
            path (if (vim.startswith path ".")
                     (pl-path.abspath path)
                     path)]
        (vim.api.nvim_cmd {:cmd command
                           :args [path]
                           :bang true
                           :mods {:silent true}} {})
        (when (or (not= line 1) (not= col 1))
          (vim.api.nvim_win_set_cursor 0 [line (- col 1)])
          (vim.api.nvim_feedkeys :zz :n false))))))

(fn file-actions []
  (let [actions (require :fzf-lua.actions)]
    {:default (partial edit-or-qf (partial edit :edit))
     :ctrl-s (partial edit-or-qf (partial edit :split))
     :ctrl-x (partial edit-or-qf (partial edit :split))
     :ctrl-v (partial edit-or-qf (partial edit :vsplit))
     :ctrl-t (partial edit-or-qf (partial edit :tabedit))
     :ctrl-q actions.file_sel_to_qf}))

(fn save-stack-and-edit [selected]
  (let [winid (vim.api.nvim_get_current_win)
        [lnum col] (vim.api.nvim_win_get_cursor winid)
        col (+ col 1)]
    (vim.fn.settagstack (vim.api.nvim_get_current_win)
                        {:items [{:tagname (vim.fn.expand :<cword>)
                                  :from [(vim.api.nvim_get_current_buf)
                                         lnum
                                         col
                                         0]}]} :a)
    (edit :edit selected)))

(macro lsp-actions []
  `(let [actions# (file-actions)]
     (tset actions# :default (partial edit-or-qf save-stack-and-edit))
     actions#))

(local fzf-lua (mod-invoke :fsouza.lib.nvim-helpers :once
                           (fn []
                             (vim.cmd.packadd :nvim-fzf)
                             (let [actions (file-actions)
                                   fzf-lua- (require :fzf-lua)
                                   f-utils (require :fzf-lua.utils)
                                   f-config (require :fzf-lua.config)
                                   id #$1]
                               (fzf-lua-.setup {:fzf_args vim.env.FZF_DEFAULT_OPTS
                                                :fzf_layout :default
                                                :previewers {:builtin {:syntax false}}
                                                :buffers {:file_icons false
                                                          :git_icons false
                                                          :color_icons false}
                                                :files {:file_icons false
                                                        :git_icons false
                                                        :color_icons false
                                                        : actions}
                                                :git {:files {:file_icons false
                                                              :git_icons false
                                                              :color_icons false
                                                              : actions}}
                                                :grep {:file_icons false
                                                       :git_icons false
                                                       :color_icons false
                                                       : actions}
                                                :oldfiles {:file_icons false
                                                           :git_icons false
                                                           :color_icons false
                                                           : actions}
                                                :lsp {:file_icons false
                                                      :git_icons false
                                                      :color_icons false
                                                      :actions (lsp-actions)}
                                                :winopts {:win_height 0.85
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
                               (tset f-config.globals.keymap.fzf :ctrl-f nil)
                               (tset f-config.globals.keymap.fzf :ctrl-b nil)
                               (each [name _ (pairs f-utils.ansi_codes)]
                                 (tset f-utils.ansi_codes name id))
                               fzf-lua-))))

(fn send-items [items prompt]
  (let [prompt (.. prompt "：")
        fzf-lua (fzf-lua)
        config (require :fzf-lua.config)
        core (require :fzf-lua.core)
        make-entry (require :fzf-lua.make_entry)
        opts (config.normalize_opts {: prompt :cwd (vim.loop.cwd)}
                                    config.globals.lsp)
        contents (icollect [_ item (ipairs items)]
                   (let [item (make-entry.lcol item opts)]
                     (make-entry.file item opts)))]
    (core.fzf_exec contents opts)))

(fn grep [rg-opts search extra-opts]
  (let [search (or search (vim.fn.input "rg："))
        extra-opts (or extra-opts "")
        fzf-lua (fzf-lua)]
    (when (not= search "")
      (fzf-lua.grep {: search
                     :raw_cmd (string.format "rg %s %s -- %s" rg-opts
                                             extra-opts
                                             (vim.fn.shellescape search))}))))

(fn live-grep [rg-opts]
  (let [fzf-lua (fzf-lua)]
    (fzf-lua.live_grep_native {:rg_opts rg-opts :multiprocess true})))

(fn handle-repo [run-fzf cd selected]
  (when (= (length selected) 1)
    (let [[sel] selected
          sel (mod-invoke :fsouza.pl.path :abspath sel)]
      (when cd
        (vim.api.nvim_set_current_dir sel))
      (when run-fzf
        (let [fzf-lua (fzf-lua)]
          (fzf-lua.files sel)
          (mod-invoke :fzf-lua.actions :ensure_insert_mode))))))

(fn git-repos [cwd cd run-fzf]
  (let [run-fzf (or run-fzf true)
        cd (or cd true)
        prompt "Git repos："
        cwd (or cwd (vim.loop.cwd))
        fzf-lua (fzf-lua)
        config (require :fzf-lua.config)
        core (require :fzf-lua.core)
        opts (config.normalize_opts {: prompt
                                     : cwd
                                     :actions {:default (partial handle-repo
                                                                 run-fzf cd)}}
                                    config.globals.files)
        contents (core.mt_cmd_wrapper {:cmd "fd --hidden --type d --exec dirname {} ';' -- '^.git$'"})
        opts (core.set_fzf_field_index opts)]
    (tset opts.fzf_opts :--no-multi "")
    (tset opts :previewer nil)
    (core.fzf_exec contents opts)))

(fn git-files []
  (let [fzf-lua (fzf-lua)]
    (fzf-lua.git_files {:cwd (vim.loop.cwd)})))

(let [rg-opts "--column -n --hidden --no-heading --color=always --colors 'match:fg:0x99,0x00,0x00' --colors line:none --colors path:none --colors column:none -S --glob '!.git' --glob '!.hg'"
      mod {: git-files
           :live-grep #(live-grep rg-opts)
           :grep (partial grep rg-opts)
           :grep-visual #(grep rg-opts
                               (. (mod-invoke :fsouza.lib.nvim-helpers
                                              :get-visual-selection-contents)
                                  1) :-F)
           : git-repos
           : send-items}]
  (setmetatable mod {:__index (fn [table key]
                                (let [fzf-lua (fzf-lua)
                                      value (. fzf-lua key)]
                                  (rawset table key value)
                                  value))}))
