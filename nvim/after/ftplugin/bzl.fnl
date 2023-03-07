(import-macros {: mod-invoke} :helpers)

(let [path (require :fsouza.pl.path)
      bufnr (vim.api.nvim_get_current_buf)
      buildifierw (path.join _G.config-dir :langservers :bin :buildifierw.py)
      py3 (path.join _G.cache-dir :venv :bin :python3)
      buildifier {:formatCommand (string.format "%s %s ${INPUT}" py3
                                                buildifierw)
                  :formatStdin true}]
  (mod-invoke :fsouza.lsp.servers.efm :add bufnr :bzl [buildifier]))
