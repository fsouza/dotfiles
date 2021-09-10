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

local function set_folding()
  local tablex = require('fsouza.tablex')

  local helpers = require('fsouza.lib.nvim_helpers')
  local file_types = tablex.flat_map(lang_to_ft, wanted_parsers)

  local foldexpr = 'nvim_treesitter#foldexpr()'
  tablex.foreach(file_types, function(ft)
    if ft == vim.bo.filetype then
      vim.wo.foldmethod = 'expr'
      vim.wo.foldexpr = foldexpr
    end
  end)

  helpers.augroup('folding_config', {
    {
      events = {'FileType'};
      targets = file_types;
      command = [[setlocal foldmethod=expr foldexpr=]] .. foldexpr;
    };
  })
end

do
  local configs = require('nvim-treesitter.configs')
  configs.setup({
    highlight = {enable = false};
    incremental_selection = {
      enable = true;
      keymaps = {
        init_selection = 'gnn';
        node_incremental = '<tab>';
        scope_incremental = 'grc';
        node_decremental = '<s-tab>';
      };
    };
    playground = {enable = true; updatetime = 30};
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

  require('nvim-gps').setup({
    icons = {['class-name'] = '￠ '; ['function-name'] = 'ƒ '; ['method-name'] = 'ƒ '};
    separator = ' ＞ ';
  })
end
