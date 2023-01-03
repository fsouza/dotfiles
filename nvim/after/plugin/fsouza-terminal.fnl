(import-macros {: mod-invoke} :helpers)

(do
  (fn term-open [term-id]
    (mod-invoke :fsouza.lib.terminal :open term-id))
  (macro term-mapping [term-id]
    `(vim.keymap.set :n ,(.. :<a-t> term-id) #(term-open ,term-id)))
  (term-mapping :j)
  (term-mapping :k)
  (term-mapping :l))
