(import-macros {: mod-invoke} :helpers)

(fn is-python-test [fname]
  (or (not= (string.find fname "test_.*%.py$") nil)
      (not= (string.find fname ".*_test%.py$") nil)))

(fn start-pyright [bufnr python-interpreter]
  (let [python-interpreter (or python-interpreter
                               (vim.fs.joinpath _G.cache-dir :venv :bin
                                                :python3))]
    (mod-invoke :fsouza.lsp.servers :start
                {: bufnr
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
                 :opts {:diagnostic-filter #(mod-invoke :fsouza.lsp.servers.pyright
                                                        :valid-diagnostic $1)}
                 :cb #(mod-invoke :fsouza.lsp.references :register-test-checker
                                  :.py :python is-python-test)})))

(fn get-python-tools [cb]
  (let [gen-python-tools (vim.fs.joinpath _G.dotfiles-cache-dir :bin
                                          :gen-efm-python-tools)]
    (fn on-finished [result]
      (if (not= result.exit-status 0)
          (error result.stderr)
          (->> result.stdout
               (vim.json.decode)
               (cb))))

    (mod-invoke :fsouza.lib.cmd :run gen-python-tools
                {:args [:-venv (vim.fs.joinpath _G.cache-dir :venv)]}
                on-finished)))

(let [bufnr (vim.api.nvim_get_current_buf)]
  (get-python-tools #(let [tools $1]
                       (vim.schedule #(mod-invoke :fsouza.lsp.servers.efm :add
                                                  bufnr :python tools))))
  (mod-invoke :fsouza.lib.python :detect-interpreter
              #(let [interpreter $1]
                 (vim.schedule #(start-pyright bufnr interpreter)))))
