(fn add [command-name]
  (vim.api.nvim_create_user_command command-name
                                    #(vim.api.nvim_create_autocmd [:User]
                                                                  {:pattern [:PluginReady]
                                                                   :once true
                                                                   :command command-name})
                                    {:force false}))

{: add}
