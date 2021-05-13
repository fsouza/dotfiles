local api = vim.api
local vfn = vim.fn
local helpers = require('fsouza.lib.nvim_helpers')

local M = {}

local function cr_key_for_comp_info(comp_info)
  if comp_info.mode == '' then
    return [[<cr>]]
  end
  if comp_info.pum_visible == 1 and comp_info.selected == -1 then
    return [[<c-e><cr>]]
  end
  return [[<cr>]]
end

local cr_cmd = helpers.ifn_map(function()
  local r = cr_key_for_comp_info(vfn.complete_info())
  return api.nvim_replace_termcodes(r, true, false, true)
end)

function M.on_attach(bufnr)
  require('compe').setup({
    enabled = true;
    autocomplete = false;
    preselect = 'disable';
    source = {nvim_lsp = true};
  }, bufnr)

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
        {lhs = '<cr>'; rhs = cr_cmd; opts = {noremap = true}};
        {lhs = '<c-x><c-o>'; rhs = [[compe#complete()]]; opts = {expr = true; silent = true}};
        {lhs = '<c-y>'; rhs = [[compe#confirm('<c-y>')]]; opts = {expr = true; silent = true}};
      };
    }, bufnr)
  end)
end

return M
