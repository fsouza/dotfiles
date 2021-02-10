local vfn = vim.fn

local M = {}

local plugs = {
  {repo = 'chaoren/vim-wordmotion'};
  {repo = 'godlygeek/tabular'};
  {repo = 'junegunn/fzf.vim'};
  {repo = 'justinmk/vim-dirvish'};
  {repo = 'justinmk/vim-sneak'};
  {repo = 'kana/vim-textobj-user'};
  {repo = 'mattn/emmet-vim'};
  {repo = 'mg979/vim-visual-multi'};
  {repo = 'michaeljsmith/vim-indent-object'};
  {repo = 'neovim/nvim-lspconfig'};
  {repo = 'norcalli/nvim-colorizer.lua'};
  {repo = 'nvim-lua/completion-nvim'};
  {repo = 'nvim-treesitter/nvim-treesitter'};
  {repo = 'nvim-treesitter/nvim-treesitter-textobjects'};
  {repo = 'nvim-treesitter/playground'};
  {repo = 'rhysd/git-messenger.vim'};
  {repo = 'sheerun/vim-polyglot'};
  {repo = 'thinca/vim-textobj-between'};
  {repo = 'tpope/vim-commentary'};
  {repo = 'tpope/vim-fugitive'};
  {repo = 'tpope/vim-repeat'};
  {repo = 'tpope/vim-surround'};
}

function M.setup()
  local dir = vfn.stdpath('data') .. '/site/pack/vim-plug/start'
  vfn['plug#begin'](dir)
  for _, plug in ipairs(plugs) do
    vfn['plug#'](plug.repo, plug.opts or vim.empty_dict())
  end
  vfn['plug#end']()
end

function M.replug()
  package.loaded['fsouza.vim-plug'] = nil
  require('fsouza.vim-plug').setup()
end

function M.setup_command()
  vim.cmd([[command! Replug lua require('fsouza.vim-plug').replug()]])
end

return M
