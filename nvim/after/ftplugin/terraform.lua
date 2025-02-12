local servers = require("fsouza.lsp.servers")
local mod_dir = vim.fs.joinpath(_G.dotfiles_dir, "nvim", "langservers")

vim.bo.commentstring = "#%s"
servers.start({
  config = {
    name = "terraform-ls",
    cmd = {
      "go",
      "run",
      "-C",
      mod_dir,
      "github.com/hashicorp/terraform-ls",
      "serve",
    },
  },
  opts = { autofmt = true },
})
