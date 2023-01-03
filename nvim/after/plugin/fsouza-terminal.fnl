(import-macros {: mod-invoke} :helpers)

(macro term-mapping [term-id]
  `(vim.keymap.set :n ,(.. :<a-t> term-id)
                   #(mod-invoke :fsouza.lib.terminal :open ,term-id)))

(do
  (term-mapping :j)
  (term-mapping :k)
  (term-mapping :l))
