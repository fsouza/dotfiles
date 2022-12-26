(import-macros {: vim-schedule : if-nil : mod-invoke} :helpers)

(fn with-executable [exec cb]
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

(fn disabled-servers []
  (-> :DISABLED_LSPS (vim.loop.os_getenv) (or "")
      (vim.split "\n" {:plain true :trimempty true})))

(macro should-start [bufnr name]
  `(and (vim.api.nvim_buf_is_valid ,bufnr)
        (not= (vim.api.nvim_get_option_value :buftype {:buf ,bufnr}) :nofile)
        (not (vim.tbl_contains (disabled-servers) ,name))))

(fn with-defaults [opts]
  (let [capabilities (vim.lsp.protocol.make_client_capabilities)]
    (tset capabilities.workspace :executeCommand {:dynamicRegistration false})
    (tset capabilities.workspace :didChangeWatchedFiles
          {:dynamicRegistration true})
    (let [defaults {:handlers (require :fsouza.lsp.handlers)
                    : capabilities
                    :flags {:debounce_text_changes 0}}]
      (vim.tbl_extend :force defaults opts))))

(fn start [{: config : find-root-dir : bufnr : cb}]
  (let [find-root-dir (or find-root-dir cwd-if-not-home)
        bufnr (if-nil bufnr (vim.api.nvim_get_current_buf))
        exec (?. config :cmd 1)
        name config.name
        config (with-defaults config)
        cb (if-nil cb #nil)]
    (when (should-start bufnr name)
      (tset config :root_dir (find-root-dir))
      (with-executable exec
                       #(do
                          (tset config.cmd 1 $1)
                          (vim-schedule (->> {: bufnr}
                                             (vim.lsp.start config)
                                             (cb))))))))

{: start : patterns-with-fallback}
