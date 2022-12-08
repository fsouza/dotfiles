(import-macros {: mod-invoke} :helpers)

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
              (print r)
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
        java19w (path.join dotfiles-dir :nvim :langservers :bin :java19w)
        jdtls (path.join cache-dir :langservers :jdtls :bin :jdtls)
        config-dir (path.join cache-dir :jdtls)
        data-dir (path.join data-dir :jdtls)]
    (mod-invoke :fsouza.lsp.servers :start
                {:name :jdtls
                 :cmd [java19w
                       jdtls
                       :-configuration
                       config-dir
                       :-data
                       data-dir]
                 : settings})))

(let [java-home (vim.loop.os_getenv :JAVA_HOME)]
  (if java-home
      (detect-runtime-name java-home
                           #(let [name $1
                                  settings {:java {:configuration {:runtimes [{: name
                                                                               :path java-home
                                                                               :default true}]}}}]
                              (start-jdtls settings)))
      (start-jdtls nil)))
