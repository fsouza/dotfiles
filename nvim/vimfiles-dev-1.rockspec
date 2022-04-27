package = "vimfiles"
version = "dev-1"
description = { license = "ISC" }
source = { url = "https://github.com/fsouza/dotfiles.git" }
dependencies = {
  "lyaml ~> 6.2.7",
  "penlight ~> 1.12.0",
  "fennel ~> 1.1.0",
  "luafilesystem ~> 1.8.0",
  "fzy ~> 0.4",
  "luabitop",
  "lpeg ~> 1.0.2",
  "lrexlib-pcre ~> 2.9.1",
  "luacheck ~> 0.26.1",
}
build = { type = "builtin", modules = {} }
