local trigger_completion = vim.fn['compe#complete']
local helpers = require('fsouza.lib.nvim_helpers')

return function()
  local bufnr = vim.api.nvim_get_current_buf()
  require('fsouza.lsp.completion').enable_autocomplete(bufnr)
  helpers.augroup('nvim_complete_switch_off', {
    {
      events = {'InsertLeave'};
      targets = {string.format([[<buffer=%d>]], bufnr)};
      command = string.format([[lua require('fsouza.lsp.completion').on_attach(%d)]], bufnr);
    };
  })
  return trigger_completion()
end
