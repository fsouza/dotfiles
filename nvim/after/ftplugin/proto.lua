local servers = require("fsouza.lsp.servers")
local mod_dir = vim.fs.joinpath(_G.dotfiles_dir, "nvim", "langservers")

servers.start({
  config = {
    name = "protobuf-ls",
    cmd = {
      "go",
      "tool",
      "-C",
      mod_dir,
      "protobuf-language-server",
    },
    settings = {
      ["additional-proto-dirs"] = {},
    },
  },
})
