(fn config-fennel []
  (let [fennel (require :fennel)
        macro-path (.. fennel.macro-path ";macros/?.fnl")]
    (tset fennel :macro-path macro-path)
    fennel))

(fn startswith [str prefix]
  (if str
      (= (string.sub str 1 (length prefix)) prefix)
      false))

(fn compile-opts [opts]
  (let [{: filename} opts
        is-nvim (startswith filename :nvim/)
        globals (if (startswith filename :hammerspoon/) [:hs] is-nvim
                    [:vim :dotfiles-dir :config-dir :cache-dir :data-dir] [])
        compile-opts {:plugins []
                      : filename
                      :allowedGlobals globals
                      :unfriendly true
                      :useBitLib is-nvim}]
    (each [global-name _ (pairs _G)]
      (table.insert compile-opts.allowedGlobals global-name))
    compile-opts))

(fn compile [opts]
  (let [fennel (config-fennel)
        (ok output) (pcall fennel.compile-string opts.src (compile-opts opts))]
    (if (not ok)
        (values 1 "" output)
        (values 0 output ""))))

(fn parse-args [args]
  (let [opts {:src nil :filename nil :output nil}]
    (while (> (length args) 0)
      (let [arg (table.remove args 1)]
        (match arg
          :--stdin-filename (tset opts :filename (table.remove args 1))
          "-" (tset opts :src (io.read :*all))
          :--output (tset opts :output (table.remove args 1))
          _ (let [file (io.open arg :r)]
              (tset opts :filename arg)
              (tset opts :src (file:read :*all))
              (file:close)))))
    opts))

(fn mkdir [dir recursive]
  (let [path (require :pl.path)
        (ok _ code) (path.mkdir dir)]
    (match code
      17 recursive
      2 (if recursive
            (when (mkdir (path.dirname dir) true)
              (mkdir dir false))
            false)
      nil true
      _ false)))

(let [path (require :pl.path)
      opts (parse-args arg)
      (status-code stdout stderr) (compile opts)]
  (if (= status-code 0)
      (let [output (if opts.output
                       (do
                         (mkdir (path.dirname opts.output) true)
                         (io.open opts.output :w))
                       io.stdout)]
        (output:write stdout))
      (io.stderr:write (.. stderr "\n")))
  (os.exit status-code))
