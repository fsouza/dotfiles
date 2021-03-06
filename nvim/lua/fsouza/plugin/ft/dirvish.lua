local helpers = require('fsouza.lib.nvim_helpers')

return function(bufnr)
  helpers.create_mappings({
    n = {
      {lhs = '<c-t>'; rhs = helpers.cmd_map([[call dirvish#open('tabedit', 0)]])};
      {lhs = '<c-v>'; rhs = helpers.cmd_map([[call dirvish#open('vsplit', 0)]])};
      {lhs = '<c-x>'; rhs = helpers.cmd_map([[call dirvish#open('split', 0)]])};
    };
  }, bufnr)
end
