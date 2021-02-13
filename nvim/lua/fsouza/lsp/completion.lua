local api = vim.api
local vfn = vim.fn
local helpers = require('fsouza.lib.nvim_helpers')

local M = {}

local function setup(bufnr, autocomplete)
  local default_autocomplete = false
  if autocomplete == nil then
    autocomplete = default_autocomplete
  end
  require('compe').setup({
    enabled = true;
    autocomplete = autocomplete;
    preselect = 'disable';
    source = {nvim_lsp = true};
  }, bufnr)
end

local function enable_autocomplete(bufnr)
  setup(bufnr, true)
end

local function cr_key_for_comp_info(comp_info)
  if comp_info.mode == '' then
    return [[<cr>]]
  end
  if comp_info.pum_visible == 1 and comp_info.selected == -1 then
    return [[<c-e><cr>]]
  end
  return [[<cr>]]
end

local function cr()
  local r = cr_key_for_comp_info(vfn.complete_info())
  return api.nvim_replace_termcodes(r, true, false, true)
end

local function complete(bufnr)
  enable_autocomplete(bufnr)
  helpers.augroup('fsouza__nvim_completion_switch_off', {
    {
      events = {'InsertLeave'};
      targets = {'<buffer>'};
      modifiers = {'++once'};
      command = helpers.fn_cmd(function()
        -- reset autocomplete
        setup(bufnr)
      end);
    };
  })
  return require('compe')._complete()
end

function M.on_attach(bufnr)
  setup(bufnr)
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
        {lhs = '<cr>'; rhs = helpers.ifn_map(cr); opts = {noremap = true}};
        {
          lhs = '<c-x><c-o>';
          rhs = helpers.ifn_map(function()
            return complete(bufnr)
          end);
          opts = {silent = true};
        };
        {lhs = '<c-y>'; rhs = [[compe#confirm('<c-y>')]]; opts = {expr = true; silent = true}};
      };
    }, bufnr)
  end)
end

return M
