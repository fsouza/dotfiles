(import-macros {: mod-invoke} :helpers)

(fn find-java-home [java-version cb]
  (fn on-finished [result]
    (when (= result.exit-status 0)
      (cb (vim.trim result.stdout))))

  (mod-invoke :fsouza.lib.cmd :run :/usr/libexec/java_home
              {:args [:-v java-version]} nil on-finished))

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

{: find-java-home : detect-runtime-name}
