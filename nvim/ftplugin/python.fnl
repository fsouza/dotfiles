(import-macros {: mod-invoke : if-nil : vim-schedule} :helpers)

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

(let [bufnr (vim.api.nvim_get_current_buf)]
  (mod-invoke :fsouza.lib.python :detect-interpreter
              #(vim-schedule (start-pyright bufnr $1))))
