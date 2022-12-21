(import-macros {: mod-invoke} :helpers)
(import-macros {: find-venv-bin} :lsp-helpers)

(let [path (require :fsouza.pl.path)
      bufnr (vim.api.nvim_get_current_buf)
      buildifierw (path.join config-dir :langservers :bin :buildifierw.py)
      py3 (find-venv-bin :python3)
      buildifier {:formatCommand (string.format "%s %s ${INPUT}" py3
                                                buildifierw)
                  :formatStdin true
                  :env [(.. :NVIM_CACHE_DIR= cache-dir)]}]
  (mod-invoke :fsouza.lsp.servers.efm :add bufnr :bzl [buildifier]))
