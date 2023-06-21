(import-macros {: mod-invoke} :helpers)

(var classpath nil)

(lambda start-groovy-language-server [bufnr java-home ?classpath]
  (let [path (require :fsouza.pl.path)
        server-jar (path.join _G.cache-dir :langservers :groovy-language-server
                              :build :libs :groovy-language-server-all.jar)
        java-bin (path.join java-home :bin :java)
        settings {:groovy {: classpath}}]
    (mod-invoke :fsouza.lsp.servers :start
                {: bufnr
                 :config {:name :groovy-language-server
                          :cmd [java-bin :-jar server-jar]
                          :cmd_env {:JAVA_HOME java-home}
                          : settings}})))

(let [bufnr (vim.api.nvim_get_current_buf)]
  (mod-invoke :fsouza.lib.java :find-java-home :11
              #(let [java-home $1]
                 (if classpath
                     (start-groovy-language-server bufnr java-home classpath)
                     (if (mod-invoke :fsouza.lib.ff :is-enabled
                                     :groovyls-classpath)
                         (mod-invoke :fsouza.lib.java.classpath
                                     :gradle-classpath-items
                                     #(start-groovy-language-server bufnr
                                                                    java-home $1))
                         (start-groovy-language-server bufnr java-home nil))))))
