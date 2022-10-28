(import-macros {: mod-invoke : if-nil} :helpers)
(import-macros {: node-lsp-cmd} :lsp-helpers)

(let [path (require :fsouza.pl.path)]
  (mod-invoke :fsouza.lsp.servers :start
              {:name :pyright
               :cmd (node-lsp-cmd :pyright-langserver :--stdio)
               :settings {:pyright {}
                          :python {:pythonPath (path.join cache-dir :venv :bin
                                                          :python3)
                                   :analysis {:autoImportCompletions true
                                              :autoSearchPaths true
                                              :diagnosticMode :workspace
                                              :typeCheckingMode (if-nil vim.g.pyright_type_checking_mode
                                                                        :basic)
                                              :useLibraryCodeForTypes true}}}
               :on_init (fn [client]
                          (mod-invoke :fsouza.lsp.pyright :detect-pythonPath
                                      client)
                          true)}))
