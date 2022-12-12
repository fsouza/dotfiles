(import-macros {: mod-invoke : vim-schedule} :helpers)

(fn lock-file-path [name]
  (let [path (require :fsouza.pl.path)
        cwd (vim.loop.cwd)]
    (path.join cache-dir :fsouza-locks (string.sub cwd 2) name)))

(lambda unlock [name cb]
  (let [lock-file (lock-file-path name)]
    (vim.loop.fs_unlink lock-file)))

(fn setup-autocmd [name]
  (mod-invoke :fsouza.lib.nvim-helpers :augroup
              (string.format "fsouza-autounlock-%s" name)
              [{:events [:VimLeavePre]
                :targets ["*"]
                :callback #(unlock name)
                :once true}]))

(lambda with-lock [name cb]
  (let [path (require :fsouza.pl.path)
        dir-perm 448 ;; 0o700
        file-perm 384 ;; 0o600
        lock-file (lock-file-path name)]
    (path.async-mkdir (path.dirname lock-file) dir-perm true
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
