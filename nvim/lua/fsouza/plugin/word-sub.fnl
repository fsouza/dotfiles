(fn run []
  (let [word (vim.fn.expand :<cword>)]
    (vim.api.nvim_input (.. ":%s/\\v<lt>" word :>//g<left><left>))))

{: run}
