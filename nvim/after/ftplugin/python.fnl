(import-macros {: mod-invoke} :helpers)

(fn is-python-test [fname]
  (or (not= (string.find fname "test_.*%.py$") nil)
      (not= (string.find fname ".*_test%.py$") nil)))

(fn start-pyright [bufnr python-interpreter]
  (let [path (require :fsouza.pl.path)
        python-interpreter (or python-interpreter
                               (path.join _G.cache-dir :venv :bin :python3))]
    (mod-invoke :fsouza.lsp.servers :start
                {: bufnr
                 :config {:name :pyright
                          :cmd [:pyright-langserver :--stdio]
                          :settings {:pyright {}
                                     :python {:pythonPath python-interpreter
                                              :analysis {:autoImportCompletions true
                                                         :autoSearchPaths true
                                                         :diagnosticMode :workspace
                                                         :typeCheckingMode (or vim.g.pyright_type_checking_mode
                                                                               :basic)
                                                         :useLibraryCodeForTypes true}}}}
                 :cb #(mod-invoke :fsouza.lsp.references :register-test-checker
                                  :.py :python is-python-test)})))

(fn get-python-tools [cb]
  (let [path (require :fsouza.pl.path)
        gen-python-tools (path.join _G.dotfiles-dir :tools :bin
                                    :gen-efm-python-tools)]
    (fn on-finished [result]
      (if (not= result.exit-status 0)
          (error result.stderr)
          (->> result.stdout
               (vim.json.decode)
               (cb))))

    (mod-invoke :fsouza.lib.cmd :run gen-python-tools {:args [:-venv (path.join _G.cache-dir :venv)]} on-finished)))

(let [bufnr (vim.api.nvim_get_current_buf)]
  (get-python-tools #(let [tools $1]
                       (vim.schedule #(mod-invoke :fsouza.lsp.servers.efm :add
                                                  bufnr :python tools))))
  (mod-invoke :fsouza.lib.python :detect-interpreter
              #(let [interpreter $1]
                 (vim.schedule #(start-pyright bufnr interpreter)))))
