local api = vim.api
local vfn = vim.fn
local helpers = require('fsouza.lib.nvim_helpers')

local M = {}

local function setup()
  vim.g.completion_enable_auto_popup = 0
  require('completion').on_attach({
    trigger_on_delete = 1;
    auto_change_source = 1;
    confirm_key = [[\<C-y>]];
    enable_server_trigger = 0;
    enable_snippet = 'snippets.nvim';
    matching_ignore_case = 1;
    matching_smart_case = 1;
    matching_strategy_list = {'exact'; 'fuzzy'};
    chain_complete_list = {default = {{complete_items = {'lsp'}}; {complete_items = {'ts'}}}};
  })
end

local function enable_autocomplete()
  vim.g.completion_enable_auto_popup = 1
end

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
        {
          lhs = '<cr>';
          rhs = helpers.i_luaeval_map([[require('fsouza.lsp.completion').cr()]]);
          opts = {noremap = true};
        };
        {
          lhs = '<c-x><c-o>';
          rhs = helpers.i_luaeval_map([[require('fsouza.lsp.completion').complete()]]);
          opts = {silent = true};
        };
      };
    }, bufnr)
  end)
end

function M.complete()
  local bufnr = vim.api.nvim_get_current_buf()
  enable_autocomplete()
  helpers.augroup('nvim_complete_switch_off', {
    {
      events = {'InsertLeave'};
      targets = {string.format([[<buffer=%d>]], bufnr)};
      modifiers = {'++once'};
      command = string.format([[lua require('fsouza.lsp.completion').exit(%d)]], bufnr);
    };
  })
  require('completion').triggerCompletion()
  return ''
end

function M.exit()
  vim.g.completion_enable_auto_popup = 0
end

local function key_for_comp_info(comp_info)
  if comp_info.mode == '' then
    return [[<cr>]]
  end
  if comp_info.pum_visible == 1 and comp_info.selected == -1 then
    return [[<c-e><cr>]]
  end
  return [[<cr>]]
end

function M.cr()
  local r = key_for_comp_info(vfn.complete_info())
  return api.nvim_replace_termcodes(r, true, false, true)
end

return M
