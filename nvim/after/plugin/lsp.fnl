(import-macros {: mod-invoke} :helpers)

(do
  (mod-invoke :fsouza.lsp :setup)
  (vim.api.nvim_create_user_command :LspRestart
                                    #(mod-invoke :fsouza.lsp.detach :restart)
                                    {:force true})
  (vim.api.nvim_create_user_command :LspSync
                                    #(mod-invoke :fsouza.lsp.sync
                                                 :sync-all-buffers)
                                    {:force true})
  (vim.api.nvim_create_user_command :LspLogs
                                    #(let [{:fargs fargs#} $1]
                                       (mod-invoke :fsouza.lsp.log-message
                                                   :show-logs (. fargs# 1)))
                                    {:force true :nargs "?"}))
