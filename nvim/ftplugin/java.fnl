(import-macros {: mod-invoke : vim-schedule} :helpers)

(fn find-java-executable [java-version cb]
  (mod-invoke :fsouza.lib.java :find-java-home java-version
              #(let [path (require :fsouza.pl.path)
                     java-home $1
                     java-bin (path.join java-home :bin :java)]
                 (cb java-bin))))

(fn find-jdtls-jar [jdtls-dir cb]
  (let [path (require :fsouza.pl.path)
        plugins-dir (path.join jdtls-dir :plugins)]
    (fn process-dir [dir]
      (when dir
        (vim.loop.fs_readdir dir
                             #(let [entries (or $2 [])]
                                (each [_ entry (ipairs entries)]
                                  (when (vim.startswith entry.name
                                                        :org.eclipse.equinox.launcher_)
                                    (cb (path.join plugins-dir entry.name))))
                                (vim.loop.fs_closedir dir #nil)))))

    (vim.loop.fs_opendir plugins-dir #(process-dir $2) 512)))

(fn start-jdtls [bufnr settings]
  (let [path (require :fsouza.pl.path)
        jdtls-dir (path.join cache-dir :langservers :jdtls)
        shared-config-dir (path.join jdtls-dir :config_mac)
        data-dir (path.join data-dir :jdtls)
        cmd [:java
             :-Declipse.application=org.eclipse.jdt.ls.core.id1
             :-Dosgi.bundles.defaultStartLevel=4
             :-Declipse.product=org.eclipse.jdt.ls.core.product
             :-Dosgi.checkConfiguration=true
             (.. :-Dosgi.sharedConfiguration.area= shared-config-dir)
             :-Dosgi.sharedConfiguration.area.readOnly=true
             :-Dosgi.configuration.cascaded=true
             :-Xmx4G
             :--add-modules=ALL-SYSTEM
             :--add-opens
             :java.base/java.util=ALL-UNNAMED
             :--add-opens
             :java.base/java.lang=ALL-UNNAMED]]
    (fn with-executable [java-bin]
      (tset cmd 1 java-bin)
      (find-jdtls-jar jdtls-dir
                      #(do
                         (table.insert cmd :-jar)
                         (table.insert cmd $1)
                         (table.insert cmd :-data)
                         (table.insert cmd data-dir)
                         (vim-schedule (mod-invoke :fsouza.lsp.servers :start
                                                   {: bufnr
                                                    :config {:name :jdtls
                                                             : cmd
                                                             : settings}})))))

    (find-java-executable :17 with-executable)))

(let [bufnr (vim.api.nvim_get_current_buf)
      java-home (vim.loop.os_getenv :JAVA_HOME)]
  (if java-home
      (mod-invoke :fsouza.lib.java :detect-runtime-name java-home
                  #(let [name $1
                         settings {:java {:configuration {:runtimes [{: name
                                                                      :path java-home
                                                                      :default true}]}}}]
                     (start-jdtls bufnr settings)))
      (start-jdtls bufnr nil)))
