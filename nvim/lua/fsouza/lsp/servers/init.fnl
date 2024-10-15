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
    (macro fallback []
      `(vim.schedule #(-> exec
                          (vim.fn.exepath)
                          (cb false))))
    (if (vim.startswith exec "/")
        (fallback)
        (let [node-exec (vim.fs.joinpath _G.config-dir :langservers
                                         :node_modules :.bin exec)]
          (vim.uv.fs_stat node-exec
                          #(if $1
                               (fallback)
                               (if (= $2.type :file)
                                   (cb node-exec true)
                                   (fallback))))))))

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
  `(let [ff# (require :fsouza.lib.ff)]
     (and (ff#.is-enabled (ff ,name) true) (vim.api.nvim_buf_is_valid ,bufnr)
          (not= (. vim :bo bufnr :buftype) :nofile))))

(fn with-defaults [opts]
  (let [capabilities (vim.lsp.protocol.make_client_capabilities)]
    (tset capabilities.workspace :executeCommand {:dynamicRegistration false})
    (tset capabilities.workspace :didChangeWatchedFiles
          {:dynamicRegistration true})
    (tset capabilities.textDocument.completion.completionItem :snippetSupport
          false)
    (let [defaults {:handlers (require :fsouza.lsp.handlers)
                    : capabilities
                    :flags {:debounce_text_changes 150}}]
      (vim.tbl_deep_extend :force defaults opts))))

(fn file-exists [bufname cb]
  (vim.uv.fs_stat bufname #(cb (= $1 nil))))

(fn autofmt-priority [autofmt]
  (if (= autofmt true) 1
      autofmt))

(fn start [{: config : find-root-dir : bufnr : cb : opts}]
  (let [find-root-dir (or find-root-dir cwd-if-not-home)
        bufnr (or bufnr (vim.api.nvim_get_current_buf))
        exec (?. config :cmd 1)
        name config.name
        config (with-defaults config)
        cb (or cb #nil)
        opts (or opts {})
        bufname (vim.api.nvim_buf_get_name bufnr)
        uri-prefixes (vim.iter ["jdtls://" "file://"])]
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
                                  (let [formatting (require :fsouza.lsp.formatting)]
                                    (formatting.attach bufnr client-id
                                                       (autofmt-priority opts.autofmt))))
                                (when (not= opts.auto-action nil)
                                  (let [auto-action (require :fsouza.lsp.auto-action)]
                                    (auto-action.attach bufnr client-id
                                                        opts.auto-action)))
                                (when (not= opts.diagnostic-filter nil)
                                  (let [buf-diagnostic (require :fsouza.lsp.buf-diagnostic)]
                                    (buf-diagnostic.register-filter name
                                                                    opts.diagnostic-filter)))
                                (cb client-id)))))))

      ;; check specific URI prefixes because some of them should not be sent to
      ;; LSPs (e.g. fugitive://, oil://, ssh://)
      (if (uri-prefixes:any #(vim.startswith bufname $1))
          (start-)
          (file-exists bufname
                       #(if $1
                            (start-)
                            (vim.schedule #(let [{: augroup} (require :fsouza.lib.nvim-helpers)]
                                             (augroup (string.format "fsouza__lsp_start_after_save_%s_%d"
                                                                     name bufnr)
                                                      [{:events [:BufWritePost]
                                                        :targets [(string.format "<buffer=%d>"
                                                                                 bufnr)]
                                                        :once true
                                                        :callback start-}])))))))))

(fn enable-server [name]
  (let [ff- (require :fsouza.lib.ff)]
    (ff-.enable (ff name))))

(fn disable-server [name]
  (let [ff- (require :fsouza.lib.ff)]
    (ff-.disable (ff name))))

{: start : patterns-with-fallback : disable-server : enable-server}
