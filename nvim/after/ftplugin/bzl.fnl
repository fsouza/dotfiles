(import-macros {: mod-invoke} :helpers)

(let [path (require :fsouza.pl.path)
      bufnr (vim.api.nvim_get_current_buf)
      buildifierw (path.join _G.dotfiles-dir :tools :bin :buildifierw)
      buildifier {:formatCommand (string.format "%s ${INPUT}" buildifierw)
                  :formatStdin true}]
  (mod-invoke :fsouza.lsp.servers.efm :add bufnr :bzl [buildifier]))
