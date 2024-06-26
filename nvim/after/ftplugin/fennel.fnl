(let [bufnr (vim.api.nvim_get_current_buf)
      bufname (vim.api.nvim_buf_get_name bufnr)
      fnlfmt (vim.fs.joinpath _G.dotfiles-cache-dir :bin :fnlfmt)
      lua-bin (vim.fs.joinpath _G.cache-dir :hr :bin :lua)
      tools [{:formatCommand (string.format "%s -" fnlfmt)
              :formatStdin true
              :env [(.. :NVIM_CACHE_DIR= _G.cache-dir)]}]
      path (require :fsouza.lib.path)
      efm (require :fsouza.lsp.servers.efm)]
  (when (path.isrel bufname _G.dotfiles-dir)
    (table.insert tools {:lintCommand (string.format "%s %s/scripts/compile.lua --stdin-filename ${INPUT} -"
                                                     lua-bin _G.dotfiles-dir)
                         :lintStdin true
                         :lintSource :fennel
                         :lintFormats ["%f:%l:%c: %m" "%f:%l: %m"]
                         :lintIgnoreExitCode true
                         :lintAfterOpen true}))
  (tset vim.b (.. :surround_ (string.byte :f)) "(\001function: \001 \r)")
  (efm.add bufnr :fennel tools))
