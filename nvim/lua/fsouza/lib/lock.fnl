(import-macros {: mod-invoke : vim-schedule} :helpers)

(fn lock-file-path [name]
  (let [path (require :fsouza.pl.path)
        cwd (vim.loop.cwd)]
    (path.join cwd :.fsouza name)))

(fn unlock [name cb]
  (let [lock-file (lock-file-path name)]
    (vim.loop.fs_unlink lock-file)))

(fn setup-autocmd [name]
  (mod-invoke :fsouza.lib.nvim-helpers :augroup
              (string.format "fsouza-autounlock-%s" name)
              [{:events [:VimLeavePre]
                :targets ["*"]
                :callback #(unlock name)
                :once true}]))

(fn with-lock [name cb]
  (let [dir-perm 448 ;; 0o700
        file-perm 384 ;; 0o600
        lock-file (lock-file-path name)]
    (vim.loop.fs_mkdir :.fsouza dir-perm
                       #(vim.loop.fs_open lock-file
                                          (bor vim.loop.constants.O_CREAT
                                               vim.loop.constants.O_EXCL)
                                          file-perm
                                          #(when (= $1 nil)
                                             (vim.loop.fs_close $2
                                                                #(do
                                                                   (vim-schedule (setup-autocmd name))
                                                                   (cb))))))))

{: with-lock : unlock}
