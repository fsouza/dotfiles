(import-macros {: mod-invoke} :helpers)

(let [bufnr (vim.api.nvim_get_current_buf)
      path (require :fsouza.pl.path)
      zls-bin (path.join _G.cache-dir :langservers :zls :zig-out :bin :zls)
      zls-config (path.join _G.config-dir :langservers :zls.json)]
  (mod-invoke :fsouza.lsp.servers :start
              {:config {:name :zls :cmd [zls-bin :--config-path zls-config]}
               :find-root-dir #(mod-invoke :fsouza.lsp.servers
                                           :patterns-with-fallback [:go.mod] $1)
               : bufnr
               :opts {:autofmt true}}))
