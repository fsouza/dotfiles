return {
  source_dir = 'src';
  exclude = {'tl_vim.tl'};
  build_dir = 'lua';
  include_dir = {'src'};
  preload_modules = {'tl_vim'};
  skip_compat53 = true;
}
