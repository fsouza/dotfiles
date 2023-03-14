(import-macros {: mod-invoke} :helpers)

(do
  (vim.keymap.set [:o :x] :ii #(mod-invoke :various-textobjs :indentation true
                                           false))
  (vim.keymap.set [:o :x] :ai #(mod-invoke :various-textobjs :indentation false
                                           false))
  (vim.keymap.set [:o :x] :ir
                  #(mod-invoke :various-textobjs :restOfIndentation))
  (vim.keymap.set [:o :x] :ar
                  #(mod-invoke :various-textobjs :restOfIndentation)))
