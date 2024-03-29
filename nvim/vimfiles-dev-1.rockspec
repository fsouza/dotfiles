package = "vimfiles"
version = "dev-1"
description = { license = "ISC" }
source = { url = "https://github.com/fsouza/dotfiles.git" }
dependencies = {
  "penlight ~> 1.13.1",
  "fennel ~> 1.4.1",
  "luafilesystem ~> 1.8.0",
  "luabitop",
  "lpeg ~> 1.1.0",
  "lrexlib-pcre ~> 2.9.2",
  "lsha2 ~> 0.1",
  "lua_system_constants ~> 0.1.4",
}
build = { type = "builtin", modules = {} }
