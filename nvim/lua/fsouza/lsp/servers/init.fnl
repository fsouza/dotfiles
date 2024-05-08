(import-macros {: mod-invoke} :helpers)

(local disabled-servers {})

(macro fnm-exec [command]
  `[:fnm
    :exec
    :--using
    (vim.fs.joinpath _G.config-dir :langservers :.node-version)
    "--"
    (unpack ,command)])

(macro ff [server-name]
  `(.. :lsp-server- ,server-name))

(fn with-executable [exec cb]
  (when exec
    (let [node-bin (vim.fs.joinpath _G.config-dir :langservers :node_modules
                                    :.bin)
          PATH (.. node-bin ":" (os.getenv :PATH))]
      (macro fallback []
        `(vim.schedule #(-> exec
                            (vim.fn.exepath)
                            (cb false))))
      (if (vim.startswith exec "/")
          (cb exec false)
          (let [node-exec (vim.fs.joinpath node-bin exec)]
            (vim.uv.fs_stat node-exec
                            #(if $1
                                 (fallback)
                                 (if (= $2.type :file)
                                     (cb node-exec true)
                                     (fallback)))))))))

(fn cwd-if-not-home []
  (let [cwd (vim.uv.cwd)
        home (vim.uv.os_homedir)]
    (when (not= cwd home)
      cwd)))

(fn patterns-with-fallback [patterns bufname]
  (let [file (. (vim.fs.find patterns
                             {:upward true :path (vim.fs.dirname bufname)})
                1)]
    (if file
        (vim.fs.dirname file)
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

(fn file-exists [bufname cb]
  (vim.uv.fs_stat bufname #(cb (= $1 nil))))

(fn start [{: config : find-root-dir : bufnr : cb : opts}]
  (let [find-root-dir (or find-root-dir cwd-if-not-home)
        bufnr (or bufnr (vim.api.nvim_get_current_buf))
        exec (?. config :cmd 1)
        name config.name
        config (with-defaults config)
        cb (or cb #nil)
        opts (or opts {})
        bufname (vim.api.nvim_buf_get_name bufnr)
        uri-pattern "^%a+://"]
    (when (should-start bufnr name)
      (tset config :root_dir (find-root-dir bufname))

      (fn start- []
        (with-executable exec
          #(when (not= $1 "")
             (let [is-node-bin $2]
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
                                (cb client-id)))))))

      (if (string.find bufname uri-pattern)
          (start-)
          (file-exists bufname
                       #(if $1
                            (start-)
                            (vim.schedule #(mod-invoke :fsouza.lib.nvim-helpers
                                                       :augroup
                                                       (string.format "fsouza__lsp_start_after_save_%s_%d"
                                                                      name bufnr)
                                                       [{:events [:BufWritePost]
                                                         :targets [(string.format "<buffer=%d>"
                                                                                  bufnr)]
                                                         :once true
                                                         :callback start-}]))))))))

(fn enable-server [name]
  (mod-invoke :fsouza.lib.ff :enable (ff name)))

(fn disable-server [name]
  (mod-invoke :fsouza.lib.ff :disable (ff name)))

{: start : patterns-with-fallback : disable-server : enable-server}
