(import-macros {: mod-invoke} :helpers)

(local error-re
       (mod-invoke :rex_pcre :new "^([^:]+):([0-9]+):(?:([0-9]+):)? (.+)$"))

(lambda process-line [_ line]
  (let [reset-pattern ". Rebuilding...$"]
    (if (string.find line reset-pattern)
        (values :RESET nil)
        (let [(fname lnum col message) (error-re:match line)]
          (if fname
              (let [path (require :fsouza.pl.path)
                    uri (->> fname
                             (path.abspath)
                             (vim.uri_from_fname))
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
        first-arg (. args 1)
        name (string.format "ibazel-%s" first-arg)]
    (table.insert args :--color=no)
    (mod-invoke :fsouza.lib.continuous-diagnostic :start
                {: name :cmd :ibazel : args : process-line})))

(lambda ibazel-cmd [{: fargs}]
  (start fargs))

(lambda setup []
  (vim.api.nvim_create_user_command :Bazel ibazel-cmd {:force true :nargs "*"})
  (vim.api.nvim_create_user_command :IBazel ibazel-cmd {:force true :nargs "*"}))

{: setup : start}