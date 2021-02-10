local api = vim.api
local vfn = vim.fn
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

local function enable_autocomplete(bufnr)
  setup(true, bufnr)
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
        {lhs = '<c-y>'; rhs = [[compe#confirm('<c-y>')]]; opts = {expr = true; silent = true}};
      };
    }, bufnr)
  end)
end

function M.complete()
  local bufnr = vim.api.nvim_get_current_buf()
  enable_autocomplete(bufnr)
  helpers.augroup('nvim_complete_switch_off', {
    {
      events = {'InsertLeave'};
      targets = {string.format([[<buffer=%d>]], bufnr)};
      modifiers = {'++once'};
      command = string.format([[lua require('fsouza.lsp.completion').exit(%d)]], bufnr);
    };
  })
  return vfn['compe#complete']()
end

function M.exit(bufnr)
  setup(false, bufnr)
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
