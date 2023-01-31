(local path (require :pl.path))

(fn require-fennel []
  (let [fennel (require :fennel)
        macro-path (.. fennel.macro-path ";macros/?.fnl")]
    (tset fennel :macro-path macro-path)
    fennel))

(fn startswith [str prefix]
  (if str
      (= (string.sub str 1 (length prefix)) prefix)
      false))

(fn dotfiles-dir []
  (let [{: source} (debug.getinfo 1)]
    (-> source
        (string.sub 2)
        (path.abspath)
        (path.dirname)
        (path.dirname))))

(fn isrel [p start]
  (not (startswith (path.relpath p start) "../")))

(fn get-profile [dotfiles-dir filename opts]
  (match opts.profile
    :nvim :nvim
    :hammerspoon :hammerspoon
    :auto (if (isrel filename (path.join dotfiles-dir :nvim)) :nvim
              (isrel filename (path.join dotfiles-dir :hammerspoon)) :hammerspoon
              :unknown)
    _ :unknown))

(fn compile-opts [opts]
  (let [{: filename} opts
        filename (path.abspath filename)
        dotfiles-dir (dotfiles-dir)
        profile (get-profile dotfiles-dir filename opts)
        globals (match profile
                  :hammerspoon [:hs]
                  :nvim [:vim :dotfiles-dir :config-dir :cache-dir :data-dir]
                  _ [])
        compile-opts {: filename
                      :allowedGlobals globals
                      :unfriendly true
                      :useBitLib (= profile :nvim)}]
    (each [global-name _ (pairs _G)]
      (table.insert compile-opts.allowedGlobals global-name))
    compile-opts))

(fn compile [opts]
  (let [fennel (require-fennel)
        (ok output) (pcall fennel.compile-string opts.src (compile-opts opts))]
    (if (not ok)
        (values 1 "" output)
        (values 0 output ""))))

(fn parse-args [args]
  (let [opts {:src nil :filename nil :output nil :profile :auto}]
    (while (> (length args) 0)
      (let [arg (table.remove args 1)]
        (match arg
          :--stdin-filename (tset opts :filename (table.remove args 1))
          "-" (tset opts :src (io.read :*all))
          :--profile (tset opts :profile (table.remove args 1))
          :--output (tset opts :output (table.remove args 1))
          _ (let [file (io.open arg :r)]
              (tset opts :filename arg)
              (tset opts :src (file:read :*all))
              (file:close)))))
    opts))

(fn mkdir [dir recursive]
  (let [(ok _ code) (path.mkdir dir)]
    (match code
      17 recursive
      2 (if recursive
            (when (mkdir (path.dirname dir) true)
              (mkdir dir false))
            false)
      nil true
      _ false)))

(let [opts (parse-args arg)
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
