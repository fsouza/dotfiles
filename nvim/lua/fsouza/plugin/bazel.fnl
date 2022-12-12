(import-macros {: mod-invoke} :helpers)

(local error-re
       (mod-invoke :rex_pcre :new "^([^:]+):([0-9]+):(?:([0-9]+):)? (.+)$"))

(lambda process-line [line _]
  (let [reset-pattern ". Rebuilding...$"]
    (if (string.find line reset-pattern)
        (values :RESET nil)
        (let [(fname lnum col message) (error-re:match line)]
          (if fname
              (let [uri (vim.uri_from_fname fname)
                    lnum (- (tonumber lnum) 1)
                    col (if col (- (tonumber col) 1) nil)]
                (values :DIAGNOSTIC
                        {: uri
                         : lnum
                         : col
                         :severity vim.diagnostic.severity.ERROR
                         : message
                         :source :bazel
                         :user_data line})))))))

(lambda start [args]
  (let [path (require :fsouza.pl.path)
        ibazel (path.join cache-dir :langservers :bin :ibazel)
        first-arg (. args 1)
        name (string.format "ibazel-%s" first-arg)]
    (mod-invoke :fsouza.lib.continuous-diagnostic :start
                {: name :cmd ibazel : args : process-line})))

(lambda ibazel-cmd [{: fargs}]
  (start fargs))

(lambda setup []
  (vim.api.nvim_create_user_command :Bazel ibazel-cmd {:force true :nargs "*"})
  (vim.api.nvim_create_user_command :IBazel ibazel-cmd {:force true :nargs "*"}))

{: setup : start}
