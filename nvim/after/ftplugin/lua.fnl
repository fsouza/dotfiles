(import-macros {: mod-invoke} :helpers)

(let [path (require :fsouza.pl.path)
      luacheck-bin (path.join cache-dir :hr :bin :luacheck)
      bufnr (vim.api.nvim_get_current_buf)
      luacheck {:lintCommand (string.format "%s --formatter plain --filename ${INPUT} -"
                                            luacheck-bin)
                :lintStdin true
                :lintSource :luacheck
                :lintFormats ["%f:%l:%c: %m"]
                :lintIgnoreExitCode true
                :rootMarkers [:.luacheckrc]
                :requireMarker true}
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
              :requireMarker true}]
  (mod-invoke :fsouza.lsp.servers.efm :add bufnr :lua [luacheck selene stylua]))
