(import-macros {: mod-invoke} :helpers)

(let [bufnr (vim.api.nvim_get_current_buf)]
  (mod-invoke :fsouza.lib.efm-formatters :get-shfmt
              #(mod-invoke :fsouza.lsp.efm :add bufnr :sh [$1]))
  (mod-invoke :fsouza.lsp.servers :start
              {: bufnr
               :config {:name :bashls :cmd [:bash-language-server :start]}}))
