local servers = require("fsouza.lsp.servers")
local mod_dir = vim.fs.joinpath(_G.dotfiles_dir, "nvim", "langservers")

vim.bo.commentstring = "#%s"
servers.start({
  config = {
    name = "terraform-ls",
    cmd = {
      "go",
      "tool",
      "-C",
      mod_dir,
      "terraform-ls",
      "serve",
    },
  },
  opts = { autofmt = true },
})
