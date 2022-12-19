(import-macros {: mod-invoke} :helpers)

(vim.api.nvim_set_option_value :formatexpr "" {:scope :local})
(vim.api.nvim_set_option_value :formatprg "" {:scope :local})
(mod-invoke :fsouza.lsp.servers :start
            {:config {:name :typescript-language-server
                      :cmd [:typescript-language-server :--stdio]}})
