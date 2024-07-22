(fn is-python-test [fname]
  (or (not= (string.find fname "test_.*%.py$") nil)
      (not= (string.find fname ".*_test%.py$") nil)))

(fn start-pyright [bufnr python-interpreter]
  (let [servers (require :fsouza.lsp.servers)
        python-interpreter (or python-interpreter
                               (vim.fs.joinpath _G.cache-dir :venv :bin
                                                :python3))]
    (servers.start {: bufnr
                    :config {:name :pyright
                             :cmd [:pyright-langserver :--stdio]
                             :cmd_env {:NODE_OPTIONS :--max-old-space-size=16384}
                             :settings {:pyright {}
                                        :python {:pythonPath python-interpreter
                                                 :analysis {:autoImportCompletions true
                                                            :autoSearchPaths true
                                                            :diagnosticMode (or vim.g.pyright_diagnostic_mode
                                                                                :workspace)
                                                            :typeCheckingMode (or vim.g.pyright_type_checking_mode
                                                                                  :basic)
                                                            :useLibraryCodeForTypes true}}}}
                    :opts {:diagnostic-filter (let [pyright (require :fsouza.lsp.servers.pyright)]
                                                pyright.valid-diagnostic)}
                    :cb #(let [references (require :fsouza.lsp.references)]
                           (references.register-test-checker :.py :python
                                                             is-python-test))})))

(fn start-ruff-server [bufnr root-dir]
  (let [lsp-servers (require :fsouza.lsp.servers)]
    (lsp-servers.start {: bufnr
                        :config {:name :ruff-server
                                 :cmd [(vim.fs.joinpath _G.cache-dir :venv :bin
                                                        :ruff)
                                       :server]
                                 :init_options {:settings {:lint {:enable true}}}}
                        :find-root-dir #root-dir
                        :opts {:autofmt 2 :auto-action :source.fixAll.ruff}})))

(fn maybe-start-ruff-server [bufnr]
  (let [bufname (vim.api.nvim_buf_get_name bufnr)
        ; TODO: support pyproject.toml
        ruff-config (vim.fs.find [:ruff.toml :.ruff.toml]
                                 {:upward true
                                  :type :file
                                  :path (vim.fs.dirname bufname)})
        ruff-config (. ruff-config 1)]
    (when ruff-config
      (start-ruff-server bufnr (vim.fs.dirname ruff-config)))))

(fn get-python-tools [cb]
  (let [gen-python-tools (vim.fs.joinpath _G.dotfiles-cache-dir :bin
                                          :gen-efm-python-tools)]
    (fn on-finished [result]
      (if (not= result.code 0)
          (error result.stderr)
          (->> result.stdout
               (vim.json.decode)
               (cb))))

    (vim.system [gen-python-tools :-venv (vim.fs.joinpath _G.cache-dir :venv)]
                nil (vim.schedule_wrap on-finished))))

(let [bufnr (vim.api.nvim_get_current_buf)
      efm (require :fsouza.lsp.servers.efm)
      {: detect-interpreter} (require :fsouza.lib.python)]
  (get-python-tools #(let [tools $1]
                       (vim.schedule #(efm.add bufnr :python tools))))
  (detect-interpreter #(let [interpreter $1]
                         (vim.schedule #(start-pyright bufnr interpreter))))
  (maybe-start-ruff-server bufnr))
