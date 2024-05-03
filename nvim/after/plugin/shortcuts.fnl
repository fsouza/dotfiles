(let [shortcut (require :fsouza.lib.shortcut)]
  (shortcut.register :Dotfiles _G.dotfiles-dir)
  (shortcut.register :Site (vim.fs.joinpath _G.data-dir :site)))
