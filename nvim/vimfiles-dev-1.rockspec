package = "vimfiles"
version = "dev-1"
description = { license = "ISC" }
source = { url = "https://github.com/fsouza/dotfiles.git" }
dependencies = {
  "penlight ~> 1.14.0",
  "fennel ~> 1.4.2",
  "luafilesystem ~> 1.8.0",
  "sha1 ~> 0.6.0",
}
build = { type = "builtin", modules = {} }
