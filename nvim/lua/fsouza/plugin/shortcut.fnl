(import-macros {: vim-schedule} :helpers)

(fn fzf-dir [directory cd]
  (let [fuzzy (require :fsouza.plugin.fuzzy)]
    (if cd
        (do
          (vim.api.nvim_set_current_dir directory)
          (fuzzy.find-files))
        (fuzzy.find-files directory))))

(fn make-callback [path]
  (fn [bang]
    (let [cd (= bang "!")]
      (vim.loop.fs_stat path
                        #(when (not $1)
                           (let [is-dir (= $2.type :directory)]
                             (vim-schedule (if is-dir
                                               (fzf-dir path cd)
                                               (vim.cmd (.. "edit " path))))))))))

(fn register [command path]
  (vim.api.nvim_create_user_command command (make-callback path)
                                    {:force true :bang true}))

{: register}
