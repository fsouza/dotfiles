(import-macros {: mod-invoke} :helpers)

(fn start-kotlin-language-server [bufnr java-home]
  (let [path (require :fsouza.pl.path)
        server-bin (path.join cache-dir :langservers :kotlin-language-server
                              :server :build :install :server :bin
                              :kotlin-language-server)]
    (mod-invoke :fsouza.lsp.servers :start
                {: bufnr
                 :config {:name :kotlin-language-server
                          :cmd [server-bin]
                          :cmd_env {:JAVA_HOME java-home}}})))

(let [bufnr (vim.api.nvim_get_current_buf)]
  (mod-invoke :fsouza.lib.java :find-java-home :17
              #(start-kotlin-language-server bufnr $1)))
