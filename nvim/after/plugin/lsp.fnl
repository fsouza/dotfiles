(let [{: setup} (require :fsouza.lsp)]
  (setup)
  (vim.api.nvim_create_user_command :LspLogs
                                    #(let [{:fargs fargs#} $1
                                           log-message# (require :fsouz.alps.log-message)]
                                       (log-message#.show-logs (. fargs# 1)))
                                    {:force true :nargs "?"}))
