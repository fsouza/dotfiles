(import-macros {: vim-schedule : if-nil : mod-invoke} :helpers)

(fn if-executable [exec cb]
  (when exec
    (mod-invoke :fsouza.pl.path :async-which exec
                #(when (not= $1 "")
                   (cb)))))

(fn cwd-if-not-home []
  (let [cwd (vim.loop.cwd)
        home (vim.loop.os_homedir)]
    (when (not= cwd home)
      cwd)))

(fn patterns-with-fallback [patterns]
  (let [file (. (vim.fs.find patterns {:upward true}) 1)]
    (if file
        (mod-invoke :fsouza.pl.path :dirname file)
        (cwd-if-not-home))))

(fn start [config find-root-dir]
  (let [find-root-dir (if-nil find-root-dir cwd-if-not-home)
        bufnr (vim.api.nvim_get_current_buf)
        exec (?. config :cmd 1)
        config (mod-invoke :fsouza.lsp.opts :with-defaults config)]
    (tset config :root_dir (find-root-dir))
    (if-executable exec #(vim-schedule (vim.lsp.start config {: bufnr})))))

{: start : patterns-with-fallback}
