(import-macros {: mod-invoke} :helpers)

(var xdg-config-home nil)

(fn is-kt-test [fname]
  (not= (string.find fname "src/test/.*%.kt$") nil))

(lambda start-kotlin-language-server [bufnr
                                      java-home
                                      jvm-target
                                      xdg-config-home]
  (let [path (require :fsouza.pl.path)
        server-bin (path.join _G.cache-dir :langservers :kotlin-language-server
                              :server :build :install :server :bin
                              :kotlin-language-server)
        settings {:kotlin {:compiler {:jvm {:target jvm-target}}
                           :linting {:debounceTime 200}}}]
    (mod-invoke :fsouza.lsp.servers :start
                {: bufnr
                 :config {:name :kotlin-language-server
                          :cmd [server-bin]
                          :cmd_env {:JAVA_HOME java-home
                                    :JAVA_OPTS "-XX:MaxRAMPercentage=80"
                                    :XDG_CONFIG_HOME xdg-config-home}
                          : settings}
                 :cb #(mod-invoke :fsouza.lsp.references :register-test-checker
                                  :.kt :kotlin is-kt-test)})))

(fn auto-delete-on-exit [dirname]
  (mod-invoke :fsouza.lib.nvim-helpers :augroup
              :fsouza__kotlin__autoremove-xdg-config-home
              [{:events [:VimLeavePre]
                :targets ["*"]
                :callback #(vim.fn.system (string.format "rm -rf %s" dirname))
                :once true}]))

(fn make-xdg-config-home [cb]
  (fn with-classpath [cp-entries]
    (fn with-temp-dir [err tempdir]
      (when (= err nil)
        (vim.schedule #(auto-delete-on-exit tempdir))
        (let [path (require :fsouza.pl.path)
              content (string.format "echo %s" (table.concat cp-entries ":"))
              script-path (path.join tempdir :kotlin-language-server :classpath)]
          (path.async-mkdir (path.dirname script-path) 448 true
                            #(vim.uv.fs_open script-path :w 493
                                             #(when (= $1 nil)
                                                (let [fd $2]
                                                  (vim.uv.fs_write fd content
                                                                   nil
                                                                   #(do
                                                                      (vim.uv.fs_close fd)
                                                                      (when (= $1
                                                                               nil)
                                                                        (set xdg-config-home
                                                                             tempdir)
                                                                        (cb tempdir)))))))))))

    (let [tmpdir (or (vim.uv.os_getenv :TMPDIR) :/tmp)]
      (vim.uv.fs_mkdtemp (mod-invoke :fsouza.pl.path :join tmpdir :kls.XXXXXX)
                         with-temp-dir)))

  (if xdg-config-home
      (cb xdg-config-home)
      (mod-invoke :fsouza.lib.java.classpath :gradle-classpath-items
                  with-classpath)))

(fn add-kotlin-tools-to-efm [bufnr]
  (let [tools [{:formatCommand "ktlint --log-level=none --stdin --format"
                :formatStdin true}]]
    (mod-invoke :fsouza.lsp.servers.efm :add bufnr :kotlin tools)))

(let [bufnr (vim.api.nvim_get_current_buf)
      user-java-home (vim.uv.os_getenv :JAVA_HOME)]
  (add-kotlin-tools-to-efm bufnr)
  (mod-invoke :fsouza.lib.java :detect-runtime-name user-java-home
              #(let [name $1
                     end (length :JavaSE-)
                     target (string.sub name (+ end 1))]
                 (mod-invoke :fsouza.lib.java :find-java-home :17
                             #(let [java-home $1]
                                (make-xdg-config-home #(let [xdg-config-home $1]
                                                         (vim.schedule #(start-kotlin-language-server bufnr
                                                                                                      java-home
                                                                                                      target
                                                                                                      xdg-config-home)))))))))
