(import-macros {: mod-invoke} :helpers)

(do
  (vim.keymap.set [:o :x] :ii #(mod-invoke :various-textobjs :indentation true
                                           true))
  (vim.keymap.set [:o :x] :ai #(mod-invoke :various-textobjs :indentation false
                                           true))
  (vim.keymap.set [:o :x] :ir #(mod-invoke :various-textobjs :restOfIndentation
                                           true))
  (vim.keymap.set [:o :x] :ar #(mod-invoke :various-textobjs :restOfIndentation
                                           false)))
