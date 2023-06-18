(import-macros {: mod-invoke} :helpers)

(fn is-kt-test [fname]
  (not= (string.find fname "src/test/.*%.kt$") nil))

(fn filter-classpath [classpath]
  (let [classpath (mod-invoke :fsouza.pl.tablex :filter (or classpath [])
                              #(vim.startswith $1 "/"))]
    (if (> (length classpath) 0)
        classpath
        nil)))

(lambda start-kotlin-language-server [bufnr java-home jvm-target]
  (fn with-classpath [cp]
    (let [path (require :fsouza.pl.path)
          server-bin (path.join _G.cache-dir :langservers
                                :kotlin-language-server :server :build :install
                                :server :bin :kotlin-language-server)
          settings {:kotlin {:compiler {:jvm {:target jvm-target}
                                        :classpath (filter-classpath cp)}
                             :linting {:debounceTime 200}}}]
      (mod-invoke :fsouza.lsp.servers :start
                  {: bufnr
                   :config {:name :kotlin-language-server
                            :cmd [server-bin]
                            :cmd_env {:JAVA_HOME java-home
                                      :JAVA_OPTS "-XX:MaxRAMPercentage=80"}
                            :init_options {: settings}
                            : settings}
                   :cb #(mod-invoke :fsouza.lsp.references
                                    :register-test-checker :.kt :kotlin
                                    is-kt-test)})))

  (mod-invoke :fsouza.lib.java.classpath :gradle-classpath-items with-classpath))

(fn add-kotlin-tools-to-efm [bufnr]
  (let [tools [{:formatCommand "ktlint --log-level=none --stdin --format"
                :formatStdin true}]]
    (mod-invoke :fsouza.lsp.servers.efm :add bufnr :kotlin tools)))

(let [bufnr (vim.api.nvim_get_current_buf)
      user-java-home (vim.uv.os_getenv :JAVA_HOME)]
  (add-kotlin-tools-to-efm bufnr)
  (mod-invoke :fsouza.lib.java :detect-runtime-name user-java-home
              #(let [name $1
                     (_ end) (string.find name :JavaSE-)
                     target (string.sub name (+ end 1))]
                 (mod-invoke :fsouza.lib.java :find-java-home :17
                             #(start-kotlin-language-server bufnr $1 target)))))
