(let [path (require :fsouza.pl.path)
      bufnr (vim.api.nvim_get_current_buf)
      selene {:lintCommand "selene --display-style quiet -"
              :lintStdin true
              :lintSource :selene
              :lintFormats ["-:%l:%c: %m"]
              :lintIgnoreExitCode true
              :rootMarkers [:selene.toml]
              :requireMarker true}
      stylua {:formatCommand "stylua -"
              :formatStdin true
              :rootMarkers [:stylua.toml :.stylua.toml]
              :requireMarker true}
      efm (require :fsouza.lsp.servers.efm)]
  (efm.add bufnr :lua [selene stylua]))
