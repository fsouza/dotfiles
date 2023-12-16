(import-macros {: mod-invoke} :helpers)

(let [bufnr (vim.api.nvim_get_current_buf)]
  (mod-invoke :fsouza.lsp.servers.efm :add bufnr :bash
              [{:formatCommand "shfmt -" :formatStdin true}]))
