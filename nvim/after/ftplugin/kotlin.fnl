(import-macros {: mod-invoke} :helpers)

(fn is-kt-test [fname]
  (not= (string.find fname "src/test/.*%.kt$") nil))

(fn start-kotlin-language-server [bufnr java-home]
  (let [path (require :fsouza.pl.path)
        server-bin (path.join _G.cache-dir :langservers :kotlin-language-server
                              :server :build :install :server :bin
                              :kotlin-language-server)
        settings {:kotlin {:externalSources {:useKlsScheme true}}}]
    (mod-invoke :fsouza.lsp.servers :start
                {: bufnr
                 :config {:name :kotlin-language-server
                          :cmd [server-bin]
                          :cmd_env {:JAVA_HOME java-home
                                    :JAVA_OPTS "-XX:MaxRAMPercentage=80"}}
                 :cb #(mod-invoke :fsouza.lsp.references :register-test-checker
                                  :.kt :kotlin is-kt-test)})))

(fn add-kotlin-tools-to-efm [bufnr]
  (let [tools [{:formatCommand "ktlint --log-level=none --stdin --format"
                :formatStdin true}]]
    (mod-invoke :fsouza.lsp.servers.efm :add bufnr :kotlin tools)))

(let [bufnr (vim.api.nvim_get_current_buf)]
  (add-kotlin-tools-to-efm bufnr)
  (mod-invoke :fsouza.lib.java :find-java-home :17
              #(start-kotlin-language-server bufnr $1)))
