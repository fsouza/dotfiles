(let [{:setup setup-packages} (require :fsouza)
      {:setup setup-packer} (require :fsouza.packed)]
  (setup-packages (os.getenv :FSOUZA_DOTFILES_DIR))
  (setup-packer))
