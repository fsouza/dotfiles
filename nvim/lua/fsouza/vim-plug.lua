local vfn = vim.fn

local plugs = {
  {repo = 'justinmk/vim-dirvish'};
  {repo = 'justinmk/vim-sneak'};
  {repo = 'kana/vim-textobj-user'};
  {repo = 'mg979/vim-visual-multi'};
  {repo = 'norcalli/nvim-colorizer.lua'};
  {repo = 'sheerun/vim-polyglot'};
  {repo = 'thinca/vim-textobj-between'};
  {repo = 'tpope/vim-repeat'};
  {repo = 'tpope/vim-surround'};
  {repo = 'godlygeek/tabular'};
  {repo = 'junegunn/fzf.vim'};
  {repo = 'neovim/nvim-lspconfig'};
  {repo = 'tpope/vim-commentary'};
  {repo = 'mattn/emmet-vim'};
  {repo = 'rhysd/git-messenger.vim'};
  {repo = 'nvim-treesitter/nvim-treesitter'};
  {repo = 'nvim-treesitter/nvim-treesitter-textobjects'};
  {repo = 'nvim-treesitter/playground'};
  {repo = 'michaeljsmith/vim-indent-object'};
  {repo = 'tpope/vim-fugitive'};
  {repo = 'chaoren/vim-wordmotion'};
  {repo = 'hrsh7th/nvim-compe'};
  {repo = 'hrsh7th/vim-vsnip'};
}

return function()
  local dir = vfn.stdpath('data') .. '/site/pack/vim-plug/start'
  vfn['plug#begin'](dir)
  for _, plug in ipairs(plugs) do
    vfn['plug#'](plug.repo, plug.opts or vim.empty_dict())
  end
  vfn['plug#end']()
end
