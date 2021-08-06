local helpers = require('fsouza.lib.nvim_helpers')

return function(bufnr)
  helpers.create_mappings({
    t = {{lhs = [[<esc><esc>]]; rhs = [[<c-\><c-n>]]; opts = {noremap = true}}};
    n = {
      {
        lhs = [[<cr>]];
        rhs = helpers.fn_map(function()
          require('fsouza.plugin.terminal').cr()
        end);
        opts = {noremap = true};
      };
    };
  }, bufnr)
end
