(let [shortcut (require :fsouza.lib.shortcut)
      path (require :fsouza.pl.path)]
  (shortcut.register :Dotfiles dotfiles-dir)
  (shortcut.register :Site (path.join data-dir :site)))
