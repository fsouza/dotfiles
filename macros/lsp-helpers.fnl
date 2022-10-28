(fn get-cache-path [...]
  `(let [path# (require :fsouza.pl.path)]
     (path#.join cache-dir :langservers ,...)))

(fn get-cache-cmd [cmd]
  (get-cache-path :bin cmd))

(fn node-lsp-cmd [...]
  `(let [path# (require :fsouza.pl.path)
         nvim-python# (path#.join cache-dir :venv :bin :python3)
         nvim-node-lsp# (path#.join config-dir :langservers :bin :node-lsp.py)]
     [nvim-python# nvim-node-lsp# ,...]))

{: get-cache-path : get-cache-cmd : node-lsp-cmd}
