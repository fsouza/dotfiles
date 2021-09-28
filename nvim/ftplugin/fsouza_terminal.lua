do
  local helpers = require("fsouza.lib.nvim_helpers")
  local bufnr = vim.api.nvim_get_current_buf()

  helpers.create_mappings({
    t = {{lhs = "<esc><esc>"; rhs = "<c-\\><c-n>"; opts = {noremap = true}}};
    n = {
      {
        lhs = "<cr>";
        rhs = helpers.fn_map(function()
          require("fsouza.plugin.terminal").cr()
        end);
        opts = {noremap = true};
      };
    };
  }, bufnr)
end
