do
  local helpers = require('fsouza.lib.nvim_helpers')

  local mappings = {
    {ft = 'gomod'; patterns = {'go.mod'}};
    {ft = 'bzl'; patterns = {'Tiltfile'; '*.tilt'}};
    {ft = 'fsharp'; patterns = {'*.fs'; '*.fsx'; '*.fsi'}};
  }

  helpers.augroup('fsouza__ftdetect', vim.tbl_map(function(m)
    return {
      events = {'BufNewFile'; 'BufRead'};
      targets = m.patterns;
      command = helpers.fn_cmd(function()
        vim.o.filetype = m.ft
      end);
    }
  end, mappings))
end
