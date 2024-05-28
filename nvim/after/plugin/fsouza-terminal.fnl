(macro term-mapping [term-id]
  `(vim.keymap.set :n ,(.. :<a-t> term-id)
                   #(let [t# (require :fsouza.lib.terminal)]
                      (t#.open ,term-id))))

(do
  (term-mapping :j)
  (term-mapping :k)
  (term-mapping :l))
