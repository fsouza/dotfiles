(import-macros {: mod-invoke : custom-surround} :helpers)

(let [path (require :fsouza.pl.path)
      bufnr (vim.api.nvim_get_current_buf)
      fnlfmt (path.join _G.config-dir :langservers :bin :fnlfmt.py)
      py3 (path.join _G.cache-dir :venv :bin :python3)
      lua-bin (path.join _G.cache-dir :hr :bin :lua)
      tools [{:formatCommand (string.format "%s %s -" py3 fnlfmt)
              :formatStdin true
              :env [(.. :NVIM_CACHE_DIR= _G.cache-dir)]}
             {:lintCommand (string.format "%s %s/scripts/compile.lua --stdin-filename ${INPUT} -"
                                          lua-bin _G.dotfiles-dir)
              :lintStdin true
              :lintSource :fennel
              :lintFormats ["%f:%l:%c %m" "%f:%l: %m"]
              :lintIgnoreExitCode true}]]
  (custom-surround :f "(\001function: \001 \r)")
  (mod-invoke :fsouza.lsp.servers.efm :add bufnr :fennel tools))
