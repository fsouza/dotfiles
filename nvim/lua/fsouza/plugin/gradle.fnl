(import-macros {: mod-invoke} :helpers)

(local kotlin-error-re
       (mod-invoke :rex_pcre :new
                   "^e: ((?:file://)?[^:]+):([0-9]+):([0-9]+) (.+)$"))

(lambda process-line [line _]
  (let [reset-pattern "^Change detected, "]
    (if (string.find line reset-pattern)
        (values :RESET nil)
        (let [(uri lnum col message) (kotlin-error-re:match line)]
          (if uri
              (let [lnum (- (tonumber lnum) 1)
                    col (- (tonumber col) 1)]
                (values :DIAGNOSTIC
                        {: uri
                         : lnum
                         : col
                         :severity vim.diagnostic.severity.ERROR
                         : message
                         :source :gradle
                         :user_data line})))))))

(lambda start [args]
  (let [first-arg (. args 1)
        name (string.format "gradle-%s" first-arg)]
    (table.insert args :--continuous)
    (mod-invoke :fsouza.lib.continuous-diagnostic :start
                {: name :cmd :./gradlew : args : process-line})))

(lambda gradle-cmd [{: fargs}]
  (start fargs))

(lambda setup []
  (vim.api.nvim_create_user_command :Gradle gradle-cmd {:force true :nargs "*"}))

{: setup : start}
