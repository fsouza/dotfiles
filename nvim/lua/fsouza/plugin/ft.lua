local api = vim.api

local helpers = require('fsouza.lib.nvim_helpers')

local M = {}

local function handle()
  if vim.o.filetype and vim.o.filetype ~= '' then
    local ft_plugin = prequire('fsouza.plugin.ft.' .. vim.o.filetype)
    if ft_plugin then
      local bufnr = api.nvim_get_current_buf()
      pcall(function()
        ft_plugin(bufnr)
      end)
    end
  end
end

function M.setup()
  helpers.augroup('fsouza__ft',
                  {{events = {'FileType'}; targets = {'*'}; command = helpers.fn_cmd(handle)}})
end

return M
