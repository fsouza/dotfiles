(import-macros {: mod-invoke} :helpers)

(do
  (vim.keymap.set [:o :x] :ii
                  #(mod-invoke :various-textobjs :indentation :inner :inner))
  (vim.keymap.set [:o :x] :ai
                  #(mod-invoke :various-textobjs :indentation :outer :inner))
  (vim.keymap.set [:o :x] :ir
                  #(mod-invoke :various-textobjs :restOfIndentation :inner))
  (vim.keymap.set [:o :x] :ar
                  #(mod-invoke :various-textobjs :restOfIndentation :outer)))
