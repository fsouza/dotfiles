package = 'vimfiles'
version = 'dev-1'
description = {license = 'ISC'}
source = {url = 'https://github.com/fsouza/dotfiles.git'}
dependencies = {'lyaml ~> 6.2.7'; 'luacheck ~> 0.24.0'; 'luaformatter'; 'penlight ~> 1.5.4-1'}
build = {type = 'builtin'; modules = {}}
