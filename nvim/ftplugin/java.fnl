(import-macros {: mod-invoke} :helpers)

(let [path (require :fsouza.pl.path)
      java19w (path.join dotfiles-dir :nvim :langservers :bin :java19w)
      jdtls (path.join cache-dir :langservers :jdtls :bin :jdtls)
      config-dir (path.join cache-dir :jdtls)
      data-dir (path.join data-dir :jdtls)
      java-home (vim.loop.os_getenv :JAVA_HOME)
      settings (if java-home
                   {:configuration {:runtimes [{:name :Java-Runtime
                                                :path java-home}]}}
                   nil)]
  (mod-invoke :fsouza.lsp.servers :start
              {:name :jdtls
               :cmd [java19w jdtls :-configuration config-dir :-data data-dir]
               : settings}))
