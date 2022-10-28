(import-macros {: mod-invoke} :helpers)
(import-macros {: node-lsp-cmd} :lsp-helpers)

(let [bufnr (vim.api.nvim_get_current_buf)]
  (vim.api.nvim_buf_set_option bufnr :formatexpr "")
  (vim.api.nvim_buf_set_option bufnr :formatprg "")
  (mod-invoke :fsouza.lsp.servers :start
              {:name :typescript-language-server
               :cmd (node-lsp-cmd :typescript-language-server :--stdio)}))
