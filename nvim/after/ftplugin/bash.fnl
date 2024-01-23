(import-macros {: mod-invoke} :helpers)

(let [bufnr (vim.api.nvim_get_current_buf)]
  (mod-invoke :fsouza.lsp.servers.efm :add bufnr :bash
              [{:formatCommand "shfmt -" :formatStdin true}
               {:lintCommand "shellcheck -f gcc -x ${INPUT}"
                :lintFormats ["%f:%l:%c: %m"]
                :lintSource :shellcheck}]))
