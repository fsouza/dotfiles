local api = vim.api
local vfn = vim.fn
local helpers = require('fsouza.lib.nvim_helpers')

local M = {}

local function setup(bufnr, autocomplete)
  local cmp = require('cmp')
  require('cmp.config').set_buffer({
    completion = {autocomplete = autocomplete or false};
    mapping = {
      ['<c-y>'] = cmp.mapping.confirm({behavior = cmp.ConfirmBehavior.Replace; select = true});
    };
    sources = {{name = 'nvim_lsp'}};
  }, bufnr)
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

function M.on_attach(bufnr)
  setup(bufnr)

  require('fsouza.color').set_popup_cb(function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local whl = vim.api.nvim_win_get_option(win, 'winhighlight')
      if string.match(whl, 'CmpDocumentation') then
        return win
      end
    end
  end)

  local setup_cmd = helpers.fn_cmd(function()
    setup(bufnr)
  end)

  local complete_cmd = helpers.ifn_map(function()
    setup(bufnr, true)
    helpers.augroup('fsouza__completion_switch_off', {
      {
        events = {'InsertLeave'};
        targets = {'<buffer>'};
        modifiers = {'++once'};
        command = setup_cmd;
      };
    })
    require('cmp').complete()
    return ''
  end)

  vim.schedule(function()
    helpers.create_mappings({
      i = {
        {lhs = '<cr>'; rhs = cr_cmd; opts = {noremap = true}};
        {lhs = '<c-x><c-o>'; rhs = complete_cmd; opts = {noremap = true}};
      };
    }, bufnr)
  end)
end

return M
