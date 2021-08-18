local vcmd = vim.cmd
local vfn = vim.fn
local helpers = require('fsouza.lib.nvim_helpers')

local M = {}

local data_dir = vfn.stdpath('data')

local function download_paq()
  local dir = string.format('%s/site/pack/paqs/start/paq-nvim', data_dir)
  vfn.system(string.format('git clone https://github.com/savq/paq-nvim.git %s', dir))
  vcmd('packadd paq-nvim')
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
    'hrsh7th/nvim-compe';
    'junegunn/fzf.vim';
    'justinmk/vim-dirvish';
    'justinmk/vim-sneak';
    'kana/vim-textobj-user';
    'liuchengxu/vista.vim';
    'mattn/emmet-vim';
    'mg979/vim-visual-multi';
    'michaeljsmith/vim-indent-object';
    'neovim/nvim-lspconfig';
    'norcalli/nvim-colorizer.lua';
    'nvim-treesitter/nvim-treesitter';
    'nvim-treesitter/nvim-treesitter-textobjects';
    'nvim-treesitter/playground';
    'rhysd/git-messenger.vim';
    'sheerun/vim-polyglot';
    'thinca/vim-textobj-between';
    'tpope/vim-commentary';
    'tpope/vim-fugitive';
    'tpope/vim-repeat';
    'tpope/vim-rhubarb';
    'tpope/vim-surround';
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
