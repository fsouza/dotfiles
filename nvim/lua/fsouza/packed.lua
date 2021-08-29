local vcmd = vim.cmd
local vfn = vim.fn
local helpers = require('fsouza.lib.nvim_helpers')

local M = {}

local data_dir = vfn.stdpath('data')

local function download_paq()
  local dir = string.format('%s/site/pack/paqs/start/paq-nvim', data_dir)
  vfn.system(string.format('git clone https://github.com/savq/paq-nvim.git %s', dir))
  vcmd('packadd! paq-nvim')
end

local function load_paq()
  if not pcall(require, 'paq') then
    download_paq()
  end
  return require('paq')
end

function M.setup()
  local paq = load_paq()
  paq({
    'savq/paq-nvim';

    'chaoren/vim-wordmotion';
    'godlygeek/tabular';
    'justinmk/vim-dirvish';
    'justinmk/vim-sneak';
    'kana/vim-textobj-user';
    'liuchengxu/vista.vim';
    'mattn/emmet-vim';
    'michaeljsmith/vim-indent-object';
    'norcalli/nvim-colorizer.lua';
    'rhysd/git-messenger.vim';
    'thinca/vim-textobj-between';
    'tpope/vim-commentary';
    'tpope/vim-fugitive';
    'tpope/vim-repeat';
    'tpope/vim-rhubarb';
    'tpope/vim-surround';
    'vijaymarupudi/nvim-fzf';

    -- completion stuff
    'hrsh7th/nvim-cmp';
    'hrsh7th/cmp-nvim-lsp';
    'hrsh7th/cmp-buffer';

    -- opt stuff
    {'ibhagwan/fzf-lua'; opt = true};
    {'neovim/nvim-lspconfig'; opt = true};
    {
      'nvim-treesitter/nvim-treesitter';
      run = function()
        vcmd('TSUpdate')
      end;
      opt = true;
    };
    {'nvim-treesitter/nvim-treesitter-textobjects'; opt = true};
    {'nvim-treesitter/playground'; opt = true};
  })
  paq:sync()
end

function M.repack()
  package.loaded['fsouza.packed'] = nil
  require('fsouza.packed').setup()
  M.setup_command()
end

function M.setup_command()
  vim.cmd([[command! Repack lua require('fsouza.packed').repack()]])
  helpers.augroup('fsouza__auto_repack', {
    {
      events = {'BufWritePost'};
      targets = {vfn.expand('~/.dotfiles/nvim/lua/fsouza/packed.lua')};
      modifiers = {'++once'};
      command = 'Repack';
    };
  })
end

return M
