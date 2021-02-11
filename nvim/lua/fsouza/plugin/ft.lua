local api = vim.api

local helpers = require('fsouza.lib.nvim_helpers')

local M = {}

local function handle()
  if vim.bo.filetype and vim.bo.filetype ~= '' then
    local status, ft_plugin = pcall(require, 'fsouza.plugin.ft.' .. vim.bo.filetype)
    if status then
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
