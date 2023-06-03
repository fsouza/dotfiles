(import-macros {: mod-invoke} :helpers)

(fn is-java-test [fname]
  (not= (string.find fname "src/test/.*%.java$") nil))

(fn find-java-executable [java-version cb]
  (mod-invoke :fsouza.lib.java :find-java-home java-version
              #(let [path (require :fsouza.pl.path)
                     java-bin (path.join $1 :bin :java)]
                 (cb java-bin))))

(fn find-jdtls-jar [jdtls-dir cb]
  (let [path (require :fsouza.pl.path)
        plugins-dir (path.join jdtls-dir :plugins)]
    (fn process-dir [dir]
      (when dir
        (vim.uv.fs_readdir dir
                           #(let [entries (or $2 [])]
                              (each [_ entry (ipairs entries)]
                                (when (vim.startswith entry.name
                                                      :org.eclipse.equinox.launcher_)
                                  (cb (path.join plugins-dir entry.name))))
                              (vim.uv.fs_closedir dir #nil)))))

    (vim.uv.fs_opendir plugins-dir #(process-dir $2) 512)))

(lambda start-jdtls [bufnr settings]
  (let [path (require :fsouza.pl.path)
        jdtls-dir (path.join _G.cache-dir :langservers :jdtls)
        shared-config-dir (path.join jdtls-dir :config_mac)
        data-dir-basename (string.gsub (vim.uv.cwd) "/" "@")
        data-dir (path.join _G.data-dir :jdtls data-dir-basename)
        cmd [:java
             :-Declipse.application=org.eclipse.jdt.ls.core.id1
             :-Dosgi.bundles.defaultStartLevel=4
             :-Declipse.product=org.eclipse.jdt.ls.core.product
             :-Dlog.level=ALL
             :-Dlog.protocol=true
             :-Dosgi.checkConfiguration=true
             (.. :-Dosgi.sharedConfiguration.area= shared-config-dir)
             :-Dosgi.sharedConfiguration.area.readOnly=true
             :-Dosgi.configuration.cascaded=true
             "-XX:MaxRAMPercentage=80"
             (.. "-javaagent:" (path.join jdtls-dir :lombok.jar))
             :--add-modules=ALL-SYSTEM
             :--add-opens
             :java.base/java.util=ALL-UNNAMED
             :--add-opens
             :java.base/java.lang=ALL-UNNAMED]
        bundles (-> (path.join jdtls-dir :vscode-java-decompiler :server :*.jar)
                    (vim.fn.glob)
                    (vim.split "\n"))
        extended-client-capabilities {:classFileContentsSupport true
                                      :generateConstructorsPromptSupport true
                                      :generateToStringPromptSupport true
                                      :hashCodeEqualsPromptSupport true
                                      :inferSelectionSupport [:extractConstant
                                                              :extractMethod
                                                              :extractVariable]
                                      :moveRefactoringSupport true
                                      :overrideMethodsPromptSupport true}]
    (fn with-executable [java-bin]
      (tset cmd 1 java-bin)
      (find-jdtls-jar jdtls-dir
                      #(do
                         (table.insert cmd :-jar)
                         (table.insert cmd $1)
                         (table.insert cmd :-data)
                         (table.insert cmd data-dir)
                         (vim.schedule #(mod-invoke :fsouza.lsp.servers :start
                                                    {: bufnr
                                                     :config {:name :jdtls
                                                              :init_options {: bundles
                                                                             : settings
                                                                             :extendedClientCapabilities extended-client-capabilities}
                                                              : cmd}
                                                     :cb #(mod-invoke :fsouza.lsp.references
                                                                      :register-test-checker
                                                                      :.java
                                                                      :java
                                                                      is-java-test)})))))

    (find-java-executable :17 with-executable)))

(let [bufnr (vim.api.nvim_get_current_buf)
      java-home (vim.uv.os_getenv :JAVA_HOME)
      settings {:java {:contentProvider {:preferred :fernflower}}}]
  (if java-home
      (mod-invoke :fsouza.lib.java :detect-runtime-name java-home
                  #(let [name $1]
                     (tset settings.java :configuration
                           {:runtimes [{: name :path java-home :default true}]})
                     (start-jdtls bufnr settings)))
      (start-jdtls bufnr settings)))
