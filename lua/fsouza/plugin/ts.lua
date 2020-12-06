local wanted_parsers = {
  'bash';
  'c';
  'cpp';
  'css';
  'go';
  'javascript';
  'json';
  'lua';
  'ocaml';
  'ocaml_interface';
  'python';
  'query';
  'rust';
  'tsx';
  'typescript';
};

local function set_folding()
  local parsers = require('nvim-treesitter.parsers')
  local helpers = require('fsouza.lib.nvim_helpers')
  local file_types = {}
  for i, lang in ipairs(wanted_parsers) do
    file_types[i] = parsers.lang_to_ft(lang)
  end

  local foldexpr = 'nvim_treesitter#foldexpr()'

  file_types = vim.tbl_flatten(file_types)
  for _, ft in pairs(file_types) do
    if ft == vim.bo.filetype then
      vim.wo.foldmethod = 'expr'
      vim.wo.foldexpr = foldexpr
    end
  end

  helpers.augroup('folding_config', {
    {
      events = {'FileType'};
      targets = file_types;
      command = [[setlocal foldmethod=expr foldexpr=]] .. foldexpr;
    };
  })
end

do
  vim.cmd([[
    packadd nvim-treesitter
    packadd nvim-treesitter-textobjects
  ]])
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
          am = '@function.outer';
          ['im'] = '@function.inner';
          al = '@block.outer';
          il = '@block.inner';
          ac = '@class.outer';
          ic = '@class.inner';
        };
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
end
