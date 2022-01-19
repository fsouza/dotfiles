(do
  (vim.keymap.set :n :<c-t>
                  #(vim.api.nvim_call_function "dirvish#open" [:tabedit 0])
                  {:buffer true})
  (vim.keymap.set :n :<c-v>
                  #(vim.api.nvim_call_function "dirvish#open" [:vsplit 0])
                  {:buffer true})
  (vim.keymap.set :n :<c-x>
                  #(vim.api.nvim_call_function "dirvish#open" [:split 0])
                  {:buffer true}))
