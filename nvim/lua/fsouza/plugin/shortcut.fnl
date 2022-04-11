(import-macros {: vim-schedule} :helpers)

(fn fzf-dir [directory cd]
  (let [fuzzy (require :fsouza.plugin.fuzzy)]
    (if cd
        (do
          (vim.api.nvim_set_current_dir directory)
          (fuzzy.find-files))
        (fuzzy.find-files directory))))

(fn register [registry command path]
  (tset registry command
        #(let [cd (= $1 "!")]
           (vim.loop.fs_stat path
                             (fn [err stat]
                               (when (not err)
                                 (let [is-dir (= stat.type :directory)]
                                   (vim-schedule (if is-dir
                                                     (fzf-dir path cd)
                                                     (vim.cmd (.. "edit " path))))))))))
  (vim.api.nvim_create_user_command command
                                    (string.format "lua require('fsouza.plugin.shortcut').registry['%s'](vim.fn.expand('<bang>'))"
                                                   command)
                                    {:force true :bang true}))

(let [registry []]
  {: registry :register (partial register registry)})
