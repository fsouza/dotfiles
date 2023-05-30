(import-macros {: mod-invoke} :helpers)

(local disabled-servers {})

(fn with-executable [exec cb]
  (when exec
    (let [node-bin (mod-invoke :fsouza.pl.path :join _G.config-dir :langservers
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

(macro should-start [bufnr name]
  `(and (= (. disabled-servers ,name) nil) (vim.api.nvim_buf_is_valid ,bufnr)
        (not= (. vim :bo bufnr :buftype) :nofile)))

(fn with-defaults [opts]
  (let [capabilities (vim.lsp.protocol.make_client_capabilities)]
    (tset capabilities.workspace :executeCommand {:dynamicRegistration false})
    (tset capabilities.workspace :didChangeWatchedFiles
          {:dynamicRegistration true})
    (let [defaults {:handlers (require :fsouza.lsp.handlers)
                    : capabilities
                    :flags {:debounce_text_changes 150}}]
      (vim.tbl_extend :force defaults opts))))

(fn start [{: config : find-root-dir : bufnr : cb : force}]
  (let [find-root-dir (or find-root-dir cwd-if-not-home)
        bufnr (or bufnr (vim.api.nvim_get_current_buf))
        exec (?. config :cmd 1)
        name config.name
        config (with-defaults config)
        cb (or cb #nil)]
    (when (or force (should-start bufnr name))
      (tset config :root_dir (find-root-dir))
      (with-executable exec
        #(do
           (tset config.cmd 1 $1)
           (vim.schedule #(->> {: bufnr}
                               (vim.lsp.start config)
                               (cb))))))))

(fn enable-server [name]
  (tset disabled-servers name nil))

(fn disable-server [name]
  (tset disabled-servers name true))

{: start : patterns-with-fallback : disable-server : enable-server}
