(import-macros {: mod-invoke} :helpers)

(do
  (mod-invoke :fsouza.lsp :setup)
  (vim.api.nvim_create_user_command :LspRestart
                                    #(mod-invoke :fsouza.lsp.detach :restart)
                                    {:force true})
  (vim.api.nvim_create_user_command :LspSync
                                    #(mod-invoke :fsouza.lsp.sync
                                                 :sync-all-buffers)
                                    {:force true}))
