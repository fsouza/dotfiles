(import-macros {: mod-invoke} :helpers)

(let [bufnr (vim.api.nvim_get_current_buf)
      path (require :fsouza.pl.path)
      zls-bin (path.join _G.cache-dir :langservers :zls :zig-out :bin :zls)
      zls-config (path.join _G.config-dir :langservers :zls.json)
      tools [{:lintStdin false
              :lintIgnoreExitCode true
              :lintCommand "zig build"
              :lintWorkspace true
              :lintOnSave true
              :lintFormats ["%f:%l:%c: error: %m"]
              :lintSource :zig-build
              :rootMarkers [:build.zig]
              :requireMarker true}
             {:formatStdin true :formatCommand "zig fmt --stdin"}]]
  (mod-invoke :fsouza.lsp.servers :start
              {:config {:name :zls :cmd [zls-bin :--config-path zls-config]}
               :find-root-dir #(mod-invoke :fsouza.lsp.servers
                                           :patterns-with-fallback [:go.mod] $1)
               : bufnr
               :opts {:autofmt true}})
  (mod-invoke :fsouza.lsp.servers.efm :add bufnr :zig tools))
