package = "vimfiles"
version = "dev-1"
description = { license = "ISC" }
source = { url = "https://github.com/fsouza/dotfiles.git" }
dependencies = {
  "sha1 ~> 0.6.0",
}
build = { type = "builtin", modules = {} }
