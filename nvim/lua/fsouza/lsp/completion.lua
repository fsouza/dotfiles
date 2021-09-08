local api = vim.api
local vcmd = vim.cmd
local vfn = vim.fn
local helpers = require('fsouza.lib.nvim_helpers')

local M = {}

local autoconfirm_characters = {python = {'.'; '('}}

local function load_lsp_source()
  require('cmp_nvim_lsp').setup()
end

local function setup(bufnr, autocomplete)
  vim.cmd('packadd nvim-cmp')
  load_lsp_source()

  local cmp = require('cmp')
  require('cmp.config').set_buffer({
    completion = {autocomplete = autocomplete or false};
    mapping = {
      ['<c-y>'] = cmp.mapping.confirm({behavior = cmp.ConfirmBehavior.Replace; select = true});
    };
    snippet = {
      expand = function(args)
        require('luasnip').lsp_expand(args.body)
      end;
    };
    sources = {{name = 'nvim_lsp'}};
    documentation = {border = 'none'};
    preselect = cmp.PreselectMode.None;
    formatting = {
      format = function(entry, vim_item)
        local menu = ({nvim_lsp = 'LSP'})[entry.source.name] or entry.source.name
        vim_item.menu = '「' .. menu .. '」'
        return vim_item
      end;
    };
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

local confirm_and_esc_cmd = helpers.ifn_map(function()
  local comp_info = vfn.complete_info()
  if comp_info.pum_visible == 1 and comp_info.selected > -1 then
    local cmp = require('cmp')
    local core = require('cmp.core')
    local entry = core.menu:get_selected_entry()
    if entry then
      core.confirm(entry, {behavior = cmp.ConfirmBehavior.Replace}, function()
        cmp.close()
        vcmd([[stopinsert]])
      end)
      return ''
    end
  end
  return api.nvim_replace_termcodes([[<esc>]], true, false, true)
end)

local function autoconfirm_on_char(ch)
  return helpers.ifn_map(function()
    local comp_info = vfn.complete_info()
    if comp_info.pum_visible == 1 and comp_info.selected > -1 then
      local cmp = require('cmp')
      local core = require('cmp.core')
      local entry = core.menu:get_selected_entry()
      if entry then
        core.confirm(entry, {behavior = cmp.ConfirmBehavior.Replace}, function()
          api.nvim_input(ch)
        end)
        return ''
      end
    end
    return ch
  end)
end

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
    setup(bufnr, {require('cmp').TriggerEvent.TextChanged})
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

  local buf_mappings = {
    i = {
      {lhs = '<cr>'; rhs = cr_cmd; opts = {noremap = true}};
      {lhs = '<c-x><c-o>'; rhs = complete_cmd; opts = {noremap = true}};
      {lhs = [[<esc>]]; rhs = confirm_and_esc_cmd; opts = {noremap = true}};
    };
  }

  local ft = api.nvim_buf_get_option(bufnr, 'filetype')
  require('fsouza.tablex').foreach(autoconfirm_characters[ft] or {}, function(ch)
    table.insert(buf_mappings.i, {lhs = ch; rhs = autoconfirm_on_char(ch); opts = {noremap = true}})
  end)

  vim.schedule(function()
    helpers.create_mappings(buf_mappings, bufnr)
  end)
end

function M.on_detach(bufnr)
  if api.nvim_buf_is_valid(bufnr) then
    helpers.remove_mappings({i = {{lhs = '<cr>'}}}, bufnr)
  end

  -- probably a bad idea?
  require('cmp.config').buffers[bufnr] = nil
end

return M
