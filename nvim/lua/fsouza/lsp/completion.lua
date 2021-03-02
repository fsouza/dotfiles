local api = vim.api
local vfn = vim.fn
local helpers = require('fsouza.lib.nvim_helpers')

local M = {}

local function setup()
  vim.g.completion_enable_auto_popup = 0
  require('completion').on_attach({
    trigger_on_delete = 1;
    confirm_key = [[<c-y>]];
    enable_server_trigger = 0;
    sorting = 'length';
    matching_ignore_case = 1;
    matching_smart_case = 1;
    matching_strategy_list = {'exact'; 'fuzzy'};
    chain_complete_list = {default = {{complete_items = {'lsp'}}}};
  })
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

local cr_cmd = helpers.ifn_map(function()
  local r = cr_key_for_comp_info(vfn.complete_info())
  return api.nvim_replace_termcodes(r, true, false, true)
end)

local setup_command = helpers.fn_cmd(setup)

local complete_command = helpers.ifn_map(function()
  vim.g.completion_enable_auto_popup = 1
  helpers.augroup('fsouza__completion_switch_off', {
    {
      events = {'InsertLeave'};
      targets = {'<buffer>'};
      modifiers = {'++once'};
      command = setup_command;
    };
  })
  require('completion').triggerCompletion()
  return ''
end)

function M.on_attach(bufnr)
  setup()
  require('fsouza.color').set_popup_cb(function()
    local winid = require('completion.hover').winnr
    if api.nvim_win_is_valid(winid) then
      return winid
    end
  end)

  vim.schedule(function()
    helpers.create_mappings({
      i = {
        {lhs = '<cr>'; rhs = cr_cmd; opts = {noremap = true}};
        {lhs = '<c-x><c-o>'; rhs = complete_command; opts = {silent = true}};
      };
    }, bufnr)
  end)
end

return M
