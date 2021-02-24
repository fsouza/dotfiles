local api = vim.api
local vfn = vim.fn
local helpers = require('fsouza.lib.nvim_helpers')

local M = {}

local function run(bufnr)
  local bufname = api.nvim_buf_get_name(bufnr)
  local dir = vfn.fnamemodify(bufname, ':h')
  vfn.mkdir(dir, 'p')
end

local function register_for_buffer(bufnr)
  bufnr = bufnr or vfn.expand('<abuf>')
  if api.nvim_buf_get_name(bufnr) ~= '' then
    helpers.augroup('fsouza__mkdir_' .. bufnr, {
      {
        events = {'BufWritePre'};
        targets = {string.format('<buffer=%d>', bufnr)};
        modifiers = {'++once'};
        command = helpers.fn_cmd(function()
          run(bufnr)
        end);
      };
    })
  end
end

function M.setup()
  helpers.augroup('fsouza__mkdir', {
    {events = {'BufNew'}; targets = {'*'}; command = helpers.fn_cmd(register_for_buffer)};
  })
  register_for_buffer(api.nvim_get_current_buf())
end

return M
