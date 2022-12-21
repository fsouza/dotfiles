(import-macros {: mod-invoke : if-nil : vim-schedule} :helpers)
(import-macros {: find-venv-bin} :lsp-helpers)

(fn start-pyright [bufnr python-interpreter]
  (let [path (require :fsouza.pl.path)
        python-interpreter (if-nil python-interpreter
                                   (path.join cache-dir :venv :bin :python3))]
    (mod-invoke :fsouza.lsp.servers :start
                {: bufnr
                 :config {:name :pyright
                          :cmd [:pyright-langserver :--stdio]
                          :settings {:pyright {}
                                     :python {:pythonPath python-interpreter
                                              :analysis {:autoImportCompletions true
                                                         :autoSearchPaths true
                                                         :diagnosticMode :workspace
                                                         :typeCheckingMode (if-nil vim.g.pyright_type_checking_mode
                                                                                   :basic)
                                                         :useLibraryCodeForTypes true}}}}})))

(fn get-python-tools [cb]
  (let [path (require :fsouza.pl.path)
        py3 (find-venv-bin :python3)
        gen-python-tools (path.join config-dir :langservers :bin
                                    :gen-efm-python-tools.py)]
    (fn on-finished [result]
      (if (not= result.exit-status 0)
          (error result.stderr)
          (->> result.stdout
               (vim.fn.json_decode)
               (cb))))

    (mod-invoke :fsouza.lib.cmd :run py3 {:args [gen-python-tools]} nil
                on-finished)))

(let [bufnr (vim.api.nvim_get_current_buf)]
  (get-python-tools #(vim-schedule (mod-invoke :fsouza.lsp.servers.efm :add
                                               bufnr :python $1)))
  (mod-invoke :fsouza.lib.python :detect-interpreter
              #(vim-schedule (start-pyright bufnr $1))))
