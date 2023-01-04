(let [{: setup-packages} (require :fsouza)
      {:setup setup-packer} (require :fsouza.packed)]
  (setup-packages)
  (setup-packer))
