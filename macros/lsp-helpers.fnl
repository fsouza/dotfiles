(fn get-cache-path [...]
  `(let [path# (require :fsouza.pl.path)]
     (path#.join cache-dir :langservers ,...)))

(fn get-cache-cmd [cmd]
  (get-cache-path :bin cmd))

(fn find-venv-bin [bin-name]
  `(path.join cache-dir :venv :bin ,bin-name))

(fn if-bin [bin-to-check fallback-bin cb]
  `(vim.loop.fs_stat ,bin-to-check
                     (fn [err# stat#]
                       (if (and (= err# nil) (= stat#.type :file))
                           (,cb ,bin-to-check)
                           (,cb ,fallback-bin)))))

{: get-cache-cmd : find-venv-bin : if-bin}
