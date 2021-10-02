(import-macros {: vim-schedule} :fsouza-macros)

(fn fzf-dir [directory cd]
  (let [fuzzy (require "fsouza.plugin.fuzzy")]
    (if cd
      (do
        (vim.api.nvim_set_current_dir directory)
        (fuzzy.find-files))
      (fuzzy.find-files directory))))

(fn register [mod command path]
  (tset mod.registry command (fn [bang]
                               (let [cd (= bang "!")]
                                 (vim.loop.fs_stat path (fn [err stat]
                                                          (when (not err)
                                                            (let [is-dir (= stat.type "directory")]
                                                              (vim-schedule
                                                                (if is-dir
                                                                  (fzf-dir path cd)
                                                                  (vim.cmd (.. "edit " path)))))))))))

  (vim.cmd
    (string.format
      "command! -bang %s lua require('fsouza.plugin.shortcut').registry['%s'](vim.fn.expand('<bang>'))"
      command
      command)))

(let [mod {:registry []
           :register (fn [command path]
                       (register mod command path))}]
  mod)
