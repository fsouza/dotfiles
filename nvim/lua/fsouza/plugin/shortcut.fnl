(import-macros {: vim-schedule} :helpers)

(fn fzf-dir [directory cd]
  (let [fuzzy (require :fsouza.plugin.fuzzy)]
    (if cd
        (do
          (vim.api.nvim_set_current_dir directory)
          (fuzzy.find-files))
        (fuzzy.find-files directory))))

(fn register [mod command path]
  (tset mod.registry command
        #(let [cd (= $1 "!")]
           (vim.loop.fs_stat path
                             (fn [err stat]
                               (when (not err)
                                 (let [is-dir (= stat.type :directory)]
                                   (vim-schedule (if is-dir
                                                     (fzf-dir path cd)
                                                     (vim.cmd (.. "edit " path))))))))))
  (vim.api.nvim_add_user_command command
                                 (string.format "lua require('fsouza.plugin.shortcut').registry['%s'](vim.fn.expand('<bang>'))"
                                                command)
                                 {:force true :bang true}))

(let [mod {:registry []}]
  (tset mod :register (partial register mod))
  mod)
