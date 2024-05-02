package = "vimfiles"
version = "dev-1"
description = { license = "ISC" }
source = { url = "https://github.com/fsouza/dotfiles.git" }
dependencies = {
  "penlight ~> 1.13.1",
  "fennel ~> 1.4.1",
  "luafilesystem ~> 1.8.0",
  "luabitop",
  "lrexlib-pcre ~> 2.9.2",
  "lua_system_constants ~> 0.1.4",
  "sha1 ~> 0.6.0-1",
}
build = { type = "builtin", modules = {} }
