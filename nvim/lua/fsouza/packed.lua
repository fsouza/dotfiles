local vcmd = vim.cmd
local vfn = vim.fn
local helpers = require('fsouza.lib.nvim_helpers')

local M = {}

local data_dir = vfn.stdpath('data')

local function download_packer()
  local dir = string.format('%s/site/pack/packer/start/packer.nvim', data_dir)
  vfn.system(string.format('git clone https://github.com/wbthomason/packer.nvim %s', dir))
  vcmd('packadd packer.nvim')
end

local function load_packer()
  if not pcall(require, 'packer') then
    download_packer()
  end
  return require('packer')
end

function M.setup()
  local packer = load_packer()
  packer.startup({
    function(use)
      use('wbthomason/packer.nvim')
      use('chaoren/vim-wordmotion')
      use('godlygeek/tabular')
      use('hrsh7th/nvim-compe')
      use('junegunn/fzf.vim')
      use('justinmk/vim-dirvish')
      use('justinmk/vim-sneak')
      use('kana/vim-textobj-user')
      use('liuchengxu/vista.vim')
      use('mattn/emmet-vim')
      use('mg979/vim-visual-multi')
      use('michaeljsmith/vim-indent-object')
      use('neovim/nvim-lspconfig')
      use('norcalli/nvim-colorizer.lua')
      use('nvim-treesitter/nvim-treesitter')
      use('nvim-treesitter/nvim-treesitter-textobjects')
      use('nvim-treesitter/playground')
      use('rhysd/git-messenger.vim')
      use('sheerun/vim-polyglot')
      use('thinca/vim-textobj-between')
      use('tpope/vim-commentary')
      use('tpope/vim-fugitive')
      use('tpope/vim-repeat')
      use('tpope/vim-rhubarb')
      use('tpope/vim-surround')
    end;
    config = {compile_path = string.format('%s/site/plugin/packer_compiled.vim', data_dir)};
  })
  packer.sync()
end

function M.repack()
  package.loaded['fsouza.packed'] = nil
  require('fsouza.packed').setup()
  load_packer().sync()
  M.setup_command()
end

function M.setup_command()
  -- vim.cmd([[command! Repack lua require('fsouza.packed').repack()]])
  -- helpers.augroup('fsouza__auto_repack', {
  --   {
  --     events = {'BufWritePost'};
  --     targets = {vfn.expand('~/.dotfiles/nvim/lua/fsouza/packed.lua')};
  --     modifiers = {'++once'};
  --     command = 'Repack';
  --   };
  -- })
end

return M
