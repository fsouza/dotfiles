do
  local helpers = require('fsouza.lib.nvim_helpers')
  local bufnr = vim.api.nvim_get_current_buf()

  helpers.create_mappings({n = {{lhs = '<leader>v'; rhs = helpers.cmd_map('wincmd p')}}}, bufnr)
end
