local api = vim.api
local helpers = require('fsouza.lib.nvim_helpers')

local M = {}

local default_autocomplete = false

local function setup(autocomplete, bufnr)
  require('compe').setup({
    enabled = true;
    autocomplete = autocomplete;
    preselect = 'disable';
    source = {nvim_lsp = true; nvim_treesitter = true};
  }, bufnr)
end

function M.enable_autocomplete(bufnr)
  setup(true, bufnr)
end

function M.reattach(bufnr)
  vim.fn['compe#documentation#close']()
  setup(default_autocomplete, bufnr)
end

function M.on_attach(bufnr)
  setup(default_autocomplete, bufnr)
  require('fsouza.color').set_popup_cb(function()
    local wins = api.nvim_list_wins()
    for _, winid in ipairs(wins) do
      if api.nvim_win_is_valid(winid) and pcall(api.nvim_win_get_var, winid, 'compe_documentation') then
        return winid
      end
    end
  end)

  vim.schedule(function()
    helpers.create_mappings({
      i = {
        {lhs = '<cr>'; rhs = 'v:lua.f.cr()'; opts = {expr = true; noremap = true}};
        {lhs = '<c-x><c-o>'; rhs = 'v:lua.f.complete()'; opts = {expr = true; silent = true}};
        {lhs = '<c-y>'; rhs = [[compe#confirm('<c-y>')]]; opts = {expr = true; silent = true}};
      };
    }, bufnr)
  end)
end

return M
