(fn get-cache-path [...]
  `(let [path# (require :fsouza.pl.path)]
     (path#.join _G.cache-dir :langservers ,...)))

(fn get-cache-cmd [cmd]
  (get-cache-path :bin cmd))

{: get-cache-cmd}
