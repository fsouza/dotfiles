local path = require('pl.path')
local helpers = require('fsouza.lib.nvim_helpers')

local vcmd = vim.cmd
local vfn = vim.fn

local M = {
  paq_dir = path.join(vfn.stdpath('data'), 'site', 'pack', 'paqs');
  paqs = {
    {'savq/paq-nvim'; opt = true; as = 'paq-nvim'};

    {'chaoren/vim-wordmotion'};
    {'godlygeek/tabular'};
    {'justinmk/vim-dirvish'};
    {'justinmk/vim-sneak'};
    {'mattn/emmet-vim'};
    {'michaeljsmith/vim-indent-object'};
    {'sheerun/vim-polyglot'};
    {'tpope/vim-commentary'};
    {'tpope/vim-fugitive'};
    {'tpope/vim-repeat'};
    {'tpope/vim-rhubarb'};
    {'tpope/vim-surround'};

    -- treesitter
    {
      'nvim-treesitter/nvim-treesitter';
      run = function()
        vcmd('TSUpdate')
      end;
    };
    {'nvim-treesitter/nvim-treesitter-textobjects'};
    {'nvim-treesitter/playground'};
    {'SmiteshP/nvim-gps'; opt = true};

    -- completion stuff
    {'hrsh7th/nvim-cmp'; as = 'nvim-cmp'; opt = true};
    {'hrsh7th/cmp-nvim-lsp'; as = 'cmp-nvim-lsp'; opt = true};
    {'l3mon4d3/luasnip'; as = 'luasnip'; opt = true};

    -- opt stuff
    {'fsouza/vista.vim'; opt = true; branch = 'neovim-master-compatibility'};
    {'ibhagwan/fzf-lua'; as = 'fzf-lua'; opt = true};
    {'lewis6991/impatient.nvim'; as = 'impatient.nvim'; opt = true};
    {'neovim/nvim-lspconfig'; as = 'nvim-lspconfig'; opt = true};
    {'norcalli/nvim-colorizer.lua'; as = 'nvim-colorizer.lua'; opt = true};
    {'rhysd/git-messenger.vim'; opt = true};
    {'vijaymarupudi/nvim-fzf'; opt = true};
  };
}

local function download_paq(fn)
  local paq_repo_dir = path.join(M.paq_dir, 'opt', 'paq-nvim')

  require('fsouza.lib.cmd').run('git', {
    args = {'clone'; '--depth=1'; 'https://github.com/savq/paq-nvim.git'; paq_repo_dir};
  }, nil, function(result)
    if result.exit_status ~= 0 then
      error(string.format('failed to clone paq-nvim: %d - %s', result.exit_status, result.stderr))
    end
    vcmd('packadd! paq-nvim')
    fn(require('paq'))
  end)
end

local function with_paq(fn)
  local paq = prequire('paq')
  if paq then
    fn(paq)
    return
  end

  download_paq(fn)
end

function M.setup()
  with_paq(function(paq)
    paq:setup({paq_dir = M.paq_dir})
    paq(M.paqs)
    paq:sync()
  end)
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
