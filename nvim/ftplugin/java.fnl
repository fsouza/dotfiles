(import-macros {: mod-invoke : if-nil : vim-schedule} :helpers)

(fn find-java-executable [java-version cb]
  (fn on-finished [result]
    (when (= result.exit-status 0)
      (let [path (require :fsouza.pl.path)
            java-home (vim.trim result.stdout)
            java-bin (path.join java-home :bin :java)]
        (cb java-bin))))

  (mod-invoke :fsouza.lib.cmd :run :/usr/libexec/java_home
              {:args [:-v java-version]} nil on-finished))

(fn find-jdtls-jar [jdtls-dir cb]
  (let [path (require :fsouza.pl.path)
        plugins-dir (path.join jdtls-dir :plugins)]
    (fn process-dir [dir]
      (when dir
        (vim.loop.fs_readdir dir
                             #(let [entries (if-nil $2 [])]
                                (each [_ entry (ipairs entries)]
                                  (when (vim.startswith entry.name
                                                        :org.eclipse.equinox.launcher_)
                                    (cb (path.join plugins-dir entry.name))))
                                (vim.loop.fs_closedir dir #nil)))))

    (vim.loop.fs_opendir plugins-dir #(process-dir $2) 512)))

(fn detect-runtime-name [java-home cb]
  (fn name-from-output [line]
    (fn name-from-version-string [result]
      (let [dot-pos (string.find result "%.")
            version (string.sub result 2 (- dot-pos 1))]
        (string.format "JavaSE-%s" version)))

    (let [pattern-to-name {"\"%d+%.%d+%.%d+\"" name-from-version-string
                           "\"1%.8%." :JavaSE-1.8}]
      (each [pattern result (pairs pattern-to-name)]
        (let [(start end) (string.find line pattern)]
          (when start
            (let [r (if (= (type result) :function)
                        (result (string.sub line start end))
                        result)]
              (lua "return r")))))))

  (fn on-finished [result]
    (let [lines (vim.split result.stderr "\n")
          first-line (. lines 1)]
      (->> first-line
           (name-from-output)
           (cb))))

  (let [path (require :fsouza.pl.path)
        java-bin (path.join java-home :bin :java)]
    (mod-invoke :fsouza.lib.cmd :run java-bin {:args [:-version]} nil
                on-finished)))

(fn start-jdtls [settings]
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
                                                   {:name :jdtls
                                                    : cmd
                                                    : settings})))))

    (find-java-executable :19 with-executable)))

(let [java-home (vim.loop.os_getenv :JAVA_HOME)]
  (if java-home
      (detect-runtime-name java-home
                           #(let [name $1
                                  settings {:java {:configuration {:runtimes [{: name
                                                                               :path java-home
                                                                               :default true}]}}}]
                              (start-jdtls settings)))
      (start-jdtls nil)))
