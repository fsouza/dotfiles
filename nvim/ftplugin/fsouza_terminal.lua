do
  local helpers = require("fsouza.lib.nvim_helpers")
  local bufnr = vim.api.nvim_get_current_buf()

  helpers["create-mappings"]({
    t = {{lhs = "<esc><esc>"; rhs = "<c-\\><c-n>"; opts = {noremap = true}}};
    n = {
      {
        lhs = "<cr>";
        rhs = helpers["fn-map"](function()
          require("fsouza.plugin.terminal").cr()
        end);
        opts = {noremap = true};
      };
    };
  }, bufnr)
end
