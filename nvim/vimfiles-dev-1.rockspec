package = 'vimfiles'
version = 'dev-1'
description = {license = 'ISC'}
source = {url = 'https://github.com/fsouza/dotfiles.git'}
dependencies = {
  'lyaml ~> 6.2.7';
  'penlight ~> 1.5.4-1';
  'fennel ~> 0.10.0-1';
}
build = {type = 'builtin'; modules = {}}
