(let [bufnr (vim.api.nvim_get_current_buf)
      efm (require :fsouza.lsp.servers.efm)]
  (efm.add bufnr :sh [{:formatCommand "shfmt -" :formatStdin true}
                      {:lintCommand "shellcheck -f gcc -x ${INPUT}"
                       :lintFormats ["%f:%l:%c: %m"]
                       :lintSource :shellcheck
                       :lintAfterOpen true}]))
