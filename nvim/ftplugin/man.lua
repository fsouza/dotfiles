do
  local bufnr = vim.api.nvim_get_current_buf()
  local helpers = require("fsouza.lib.nvim_helpers")

  helpers.create_mappings({
    n = {{lhs = "q"; rhs = helpers.cmd_map("quitall"); opts = {noremap = true}}};
  }, bufnr)
end
