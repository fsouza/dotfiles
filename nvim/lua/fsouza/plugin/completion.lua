local api = vim.api
local vfn = vim.fn
local helpers = require('fsouza.lib.nvim_helpers')

local M = {}

local function load_sources(cmp, sources)
  local source_loaders = {
    buffer = function()
      cmp.register_source('buffer', require('cmp_buffer').new())
    end;
    nvim_lua = function()
      cmp.register_source('nvim_lua', require('cmp_nvim_lua').new())
    end;
    tmux = function()
      cmp.register_source('tmux', require('compe_tmux'))
    end;
    nvim_lsp = function()
      require('cmp_nvim_lsp').setup()
    end;
  }

  for _, source in ipairs(sources) do
    local load = source_loaders[source.name]

    if load then
      load()
    end
  end
end

local function setup(bufnr, sources)
  vim.cmd('packadd nvim-cmp')

  local cmp = require('cmp')
  sources = sources or {{name = 'nvim_lsp'}; {name = 'buffer'}}

  load_sources(cmp, sources)

  require('cmp.config').set_buffer({
    mapping = {
      ['<c-y>'] = cmp.mapping.confirm({behavior = cmp.ConfirmBehavior.Replace; select = true});
    };
    snippet = {
      expand = function(args)
        require('luasnip').lsp_expand(args.body)
      end;
    };
    sources = sources;
    documentation = {border = 'none'};
    preselect = cmp.PreselectMode.None;
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

function M.on_attach(bufnr, sources)
  setup(bufnr, sources)

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
