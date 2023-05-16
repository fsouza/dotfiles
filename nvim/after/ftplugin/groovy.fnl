(import-macros {: mod-invoke} :helpers)

(fn start-groovy-language-server [bufnr java-home]
  (let [path (require :fsouza.pl.path)
        server-jar (path.join _G.cache-dir :langservers :groovy-language-server
                              :build :libs :groovy-language-server-all.jar)
        java-bin (path.join java-home :bin :java)]
    (mod-invoke :fsouza.lsp.servers :start
                {: bufnr
                 :config {:name :groovy-language-server
                          :cmd [java-bin :-jar server-jar]
                          :cmd_env {:JAVA_HOME java-home}}})))

(let [bufnr (vim.api.nvim_get_current_buf)]
  (mod-invoke :fsouza.lib.java :find-java-home :11
              #(start-groovy-language-server bufnr $1)))
