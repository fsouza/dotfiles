(let [various-textobjs (require :various-textobjs)]
  (vim.keymap.set [:o :x] :ii #(various-textobjs.indentation :inner :inner))
  (vim.keymap.set [:o :x] :ai #(various-textobjs.indentation :outer :inner))
  (vim.keymap.set [:o :x] :ir #(various-textobjs.restOfIndentation :inner))
  (vim.keymap.set [:o :x] :ar #(various-textobjs.restOfIndentation :outer)))
