(import-macros {: mod-invoke : if-nil : vim-schedule} :helpers)

(fn start-pyright [python-interpreter]
  (let [path (require :fsouza.pl.path)
        python-interpreter (if-nil python-interpreter
                                   (path.join cache-dir :venv :bin :python3))]
    (mod-invoke :fsouza.lsp.servers :start
                {:name :pyright
                 :cmd [:pyright-langserver :--stdio]
                 :settings {:pyright {}
                            :python {:pythonPath python-interpreter
                                     :analysis {:autoImportCompletions true
                                                :autoSearchPaths true
                                                :diagnosticMode :workspace
                                                :typeCheckingMode (if-nil vim.g.pyright_type_checking_mode
                                                                          :basic)
                                                :useLibraryCodeForTypes true}}}})))

(mod-invoke :fsouza.lib.python :detect-interpreter
            #(vim-schedule (start-pyright $1)))
