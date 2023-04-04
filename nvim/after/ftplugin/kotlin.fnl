(import-macros {: mod-invoke} :helpers)

(fn is-kt-test [fname]
  (not= (string.find fname "src/test/.*%.kt$") nil))

(fn start-kotlin-language-server [bufnr java-home]
  (let [path (require :fsouza.pl.path)
        server-bin (path.join _G.cache-dir :langservers :kotlin-language-server
                              :server :build :install :server :bin
                              :kotlin-language-server)]
    (mod-invoke :fsouza.lsp.servers :start
                {: bufnr
                 :config {:name :kotlin-language-server
                          :cmd [server-bin]
                          :cmd_env {:JAVA_HOME java-home}}
                 :cb #(mod-invoke :fsouza.lsp.references :register-test-checker
                                  :.kt :kotlin is-kt-test)})))

(let [bufnr (vim.api.nvim_get_current_buf)]
  (mod-invoke :fsouza.lib.java :find-java-home :17
              #(start-kotlin-language-server bufnr $1)))
