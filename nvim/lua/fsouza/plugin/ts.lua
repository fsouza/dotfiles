local helpers = require('fsouza.lib.nvim_helpers')
local tablex = require('fsouza.tablex')

local M = {}

local wanted_parsers = {
  'bash';
  'c';
  'cpp';
  'css';
  'go';
  'html';
  'javascript';
  'json';
  'lua';
  'ocaml';
  'ocaml_interface';
  'ocamllex';
  'python';
  'query';
  'regex';
  'toml';
  'tsx';
  'typescript';
};

local function lang_to_ft(lang)
  local parsers = require('nvim-treesitter.parsers')
  local obj = parsers.list[lang]
  return vim.tbl_flatten({{obj.filetype or lang}; obj.used_by or {}})
end

local function get_file_types()
  return tablex.flat_map(lang_to_ft, wanted_parsers)
end

local setup_gps = helpers.once(function()
  vim.cmd([[packadd nvim-gps]])
  require('nvim-gps').setup({
    icons = {['class-name'] = '￠ '; ['function-name'] = 'ƒ '; ['method-name'] = 'ƒ '};
    separator = ' ＞ ';
  })
end)

local gps_cmd = helpers.fn_map(function()
  setup_gps()
  vim.notify(require('nvim-gps').get_location())
end)

function M.create_mappings(bufnr)
  bufnr = bufnr or vim.fn.expand('<abuf>') or vim.api.nvim_get_current_buf()

  helpers.create_mappings({n = {{lhs = '<leader>w'; rhs = gps_cmd; opts = {noremap = true}}}},
                          bufnr)
end

local function set_folding()
  local file_types = get_file_types()
  local foldexpr = 'nvim_treesitter#foldexpr()'
  helpers.augroup('fsouza__folding_config', {
    {
      events = {'FileType'};
      targets = file_types;
      command = [[setlocal foldmethod=expr foldexpr=]] .. foldexpr;
    };
  })
end

local function mappings()
  local file_types = get_file_types()
  helpers.augroup('fsouza__ts_mappings', {
    {
      events = {'FileType'};
      targets = file_types;
      command = [[lua require('fsouza.plugin.ts').create_mappings()]];
    };
  })
end

do
  local configs = require('nvim-treesitter.configs')
  configs.setup({
    highlight = {enable = false};
    playground = {enable = true; updatetime = 10};
    textobjects = {
      select = {
        enable = true;
        keymaps = {
          af = '@function.outer';
          ['if'] = '@function.inner';
          al = '@block.outer';
          il = '@block.inner';
          ac = '@class.outer';
          ic = '@class.inner';
        };
      };
      move = {
        enable = true;
        set_jumps = true;
        goto_next_start = {['<leader>m'] = '@function.outer'};
        goto_previous_start = {['<leader>M'] = '@function.outer'};
      };
      swap = {
        enable = true;
        swap_next = {['<leader>a'] = '@parameter.inner'};
        swap_previous = {['<leader>A'] = '@parameter.inner'};
      };
    };
    ensure_installed = wanted_parsers;
  })
  set_folding()
  mappings()

end

return M
