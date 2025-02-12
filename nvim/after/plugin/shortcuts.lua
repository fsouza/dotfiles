local shortcut = require("fsouza.lib.shortcut")
shortcut.register("Dotfiles", _G.dotfiles_dir)
shortcut.register("Site", vim.fs.joinpath(_G.data_dir, "site"))
