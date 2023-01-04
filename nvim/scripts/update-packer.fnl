(let [{:setup setup-packages} (require :fsouza)
      {:setup setup-packer} (require :fsouza.packed)]
  (print (vim.inspect package))
  (setup-packages (os.getenv :FSOUZA_DOTFILES_DIR))
  (setup-packer))
