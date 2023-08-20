(import-macros {: mod-invoke} :helpers)

(do
  (mod-invoke :fsouza.lsp :setup)
  (vim.api.nvim_create_user_command :LspLogs
                                    #(let [{:fargs fargs#} $1]
                                       (mod-invoke :fsouza.lsp.log-message
                                                   :show-logs (. fargs# 1)))
                                    {:force true :nargs "?"}))
