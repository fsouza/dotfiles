(import-macros {: mod-invoke} :helpers)

(fn start-kotlin-language-server [java-home]
  (let [path (require :fsouza.pl.path)
        server-bin (path.join cache-dir :langservers :kotlin-language-server
                              :server :build :install :server :bin
                              :kotlin-language-server)]
    (mod-invoke :fsouza.lsp.servers :start
                {:name :kotlin-language-server
                 :cmd [server-bin]
                 :cmd_env {:JAVA_HOME java-home}})))

(mod-invoke :fsouza.lib.java :find-java-home :17 start-kotlin-language-server)
