(let [shortcut (require :fsouza.lib.shortcut)
      path (require :fsouza.pl.path)]
  (shortcut.register :Dotfiles _G.dotfiles-dir)
  (shortcut.register :Site (path.join _G.data-dir :site)))
