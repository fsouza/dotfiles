(import-macros {: vim-schedule : if-nil : mod-invoke} :helpers)

(fn if-executable [exec cb]
  (when exec
    (let [node-bin (mod-invoke :fsouza.pl.path :join config-dir :langservers
                               :node_modules :.bin)
          PATH (.. node-bin ":" (vim.loop.os_getenv :PATH 2048))]
      (mod-invoke :fsouza.pl.path :async-which exec
                  #(when (not= $1 "")
                     (cb $1)) PATH))))

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

(macro should-start [bufnr]
  `(and (vim.api.nvim_buf_is_valid ,bufnr)
        (not= (vim.api.nvim_buf_get_option ,bufnr :buftype) :nofile)))

(fn start [{: config : find-root-dir : bufnr}]
  (let [find-root-dir (if-nil find-root-dir cwd-if-not-home)
        bufnr (if-nil bufnr (vim.api.nvim_get_current_buf))
        exec (?. config :cmd 1)
        config (mod-invoke :fsouza.lsp.opts :with-defaults config)]
    (when (should-start bufnr)
      (tset config :root_dir (find-root-dir))
      (if-executable exec
                     #(do
                        (tset config.cmd 1 $1)
                        (vim-schedule (vim.lsp.start config {: bufnr})))))))

{: start : patterns-with-fallback}
