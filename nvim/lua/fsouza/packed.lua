local vcmd = vim.cmd
local vfn = vim.fn
local helpers = require('fsouza.lib.nvim_helpers')

local M = {
  paq_dir = vim.fn.stdpath('data') .. '/site/pack/paqs/';
  paqs = {
    {'savq/paq-nvim'; as = 'paq-nvim'};

    {'chaoren/vim-wordmotion'; as = 'vim-wordmotion'};
    {'godlygeek/tabular'; as = 'tabular'};
    {'justinmk/vim-dirvish'; as = 'vim-dirvish'};
    {'justinmk/vim-sneak'; as = 'vim-sneak'};
    {'kana/vim-textobj-user'; as = 'vim-textobj-user'};
    {'mattn/emmet-vim'; as = 'emmet-vim'};
    {'michaeljsmith/vim-indent-object'; as = 'vim-indent-object'};
    {'norcalli/nvim-colorizer.lua'; as = 'nvim-colorizer.lua'};
    {'rhysd/git-messenger.vim'; as = 'git-messenger.vim'};
    {'thinca/vim-textobj-between'; as = 'vim-textobj-between'};
    {'tpope/vim-commentary'; as = 'vim-commentary'};
    {'tpope/vim-fugitive'; as = 'vim-fugitive'};
    {'tpope/vim-repeat'; as = 'vim-repeat'};
    {'tpope/vim-rhubarb'; as = 'vim-rhubarb'};
    {'tpope/vim-surround'; as = 'vim-surround'};
    {'vijaymarupudi/nvim-fzf'; as = 'nvim-fzf'};

    -- completion stuff
    {'hrsh7th/nvim-cmp'; as = 'nvim-cmp'};
    {'hrsh7th/cmp-nvim-lsp'; as = 'cmp-nvim-lsp'; opt = true};
    {'hrsh7th/cmp-buffer'; as = 'cmp-buffer'; opt = true};
    {'hrsh7th/cmp-nvim-lua'; as = 'cmp-nvim-lua'; opt = true};
    {'andersevenrud/compe-tmux'; as = 'compe-tmux'; branch = 'cmp'; opt = true};
    {'l3mon4d3/luasnip'; as = 'luasnip'; opt = true};

    -- opt stuff
    {'ibhagwan/fzf-lua'; as = 'fzf-lua'; opt = true};
    {'liuchengxu/vista.vim'; as = 'vista.vim'; opt = true};
    {'neovim/nvim-lspconfig'; as = 'nvim-lspconfig'; opt = true};
    {
      'nvim-treesitter/nvim-treesitter';
      as = 'nvim-treesitter';
      opt = true;
      run = function()
        vcmd([[packadd nvim-treesitter]])
        vcmd([[TSUpdate]])
      end;
    };
    {'nvim-treesitter/nvim-treesitter-textobjects'; as = 'nvim-treesitter-textobjects'; opt = true};
    {'nvim-treesitter/playground'; as = 'playground'; opt = true};
  };
}

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
  paq:setup({paq_dir = M.paq_dir})
  paq(M.paqs)
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
