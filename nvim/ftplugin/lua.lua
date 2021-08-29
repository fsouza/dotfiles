do
  local bufnr = vim.api.nvim_get_current_buf()

  require('fsouza.plugin.completion').on_attach(bufnr, {{name = 'nvim_lua'}; {name = 'buffer'}})
end
