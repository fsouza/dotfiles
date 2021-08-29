local api = vim.api
local vfn = vim.fn
local helpers = require('fsouza.lib.nvim_helpers')

local M = {}

local function setup(bufnr)
  local cmp = require('cmp')
  require('cmp.config').set_buffer({
    mapping = {
      ['<c-y>'] = cmp.mapping.confirm({behavior = cmp.ConfirmBehavior.Replace; select = true});
    };
    sources = {{name = 'nvim_lsp'}; {name = 'buffer'}};
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

  vim.schedule(function()
    helpers.create_mappings({i = {{lhs = '<cr>'; rhs = cr_cmd; opts = {noremap = true}}}}, bufnr)
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
