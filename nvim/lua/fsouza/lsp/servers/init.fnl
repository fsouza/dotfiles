(import-macros {: mod-invoke} :helpers)

(local disabled-servers {})

(macro fnm-exec [command]
  `[:fnm
    :exec
    :--using
    (mod-invoke :fsouza.pl.path :join _G.config-dir :langservers :.node-version)
    "--"
    (table.unpack ,command)])

(macro ff [server-name]
  `(.. :lsp-server- ,server-name))

(fn with-executable [exec cb]
  (when exec
    (let [path (require :fsouza.pl.path)
          node-bin (mod-invoke :fsouza.pl.path :join _G.config-dir :langservers
                               :node_modules :.bin)
          PATH (.. node-bin ":" (os.getenv :PATH))]
      (path.async-which exec
                        #(when (not= $1 "")
                           (cb $1 (path.isrel $1 node-bin)))
                        PATH))))

(fn cwd-if-not-home []
  (let [cwd (vim.uv.cwd)
        home (vim.uv.os_homedir)]
    (when (not= cwd home)
      cwd)))

(fn patterns-with-fallback [patterns bufname]
  (let [path (require :fsouza.pl.path)
        file (. (vim.fs.find patterns
                             {:upward true :path (path.dirname bufname)})
                1)]
    (if file
        (path.dirname file)
        (cwd-if-not-home))))

(macro should-start [bufnr name]
  `(and (mod-invoke :fsouza.lib.ff :is-enabled (ff ,name) true)
        (vim.api.nvim_buf_is_valid ,bufnr)
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

(fn file-exists [bufnr cb]
  (let [fname (vim.api.nvim_buf_get_name bufnr)]
    (vim.uv.fs_stat fname #(cb (= $1 nil)))))

(fn start [{: config : find-root-dir : bufnr : cb : opts}]
  (let [find-root-dir (or find-root-dir cwd-if-not-home)
        bufnr (or bufnr (vim.api.nvim_get_current_buf))
        exec (?. config :cmd 1)
        name config.name
        config (with-defaults config)
        cb (or cb #nil)
        opts (or opts {})]
    (when (should-start bufnr name)
      (tset config :root_dir (find-root-dir (vim.api.nvim_buf_get_name bufnr)))

      (fn start- []
        (with-executable exec
          #(let [is-node-bin $2]
             (tset config.cmd 1 $1)
             (when is-node-bin
               (tset config :cmd (fnm-exec config.cmd)))
             (vim.schedule #(let [client-id (vim.lsp.start config {: bufnr})]
                              (when opts.autofmt
                                (mod-invoke :fsouza.lsp.formatting :attach
                                            bufnr client-id))
                              (when opts.auto-action
                                (mod-invoke :fsouza.lsp.auto-action :attach
                                            bufnr client-id))
                              (cb client-id))))))

      (file-exists bufnr
                   #(if $1
                        (start-)
                        (mod-invoke :fsouza.lib.nvim-helpers :augroup
                                    (string.format "fsouza__lsp_start_after_save_%s_%d"
                                                   name bufnr)
                                    [{:events [:BufWritePost]
                                      :targets [(string.format "<buffer=%d>"
                                                               bufnr)]
                                      :once true
                                      :callback start-}]))))))

(fn enable-server [name]
  (mod-invoke :fsouza.lib.ff :enable (ff name)))

(fn disable-server [name]
  (mod-invoke :fsouza.lib.ff :disable (ff name)))

{: start : patterns-with-fallback : disable-server : enable-server}
