local mod_dir = vim.fs.joinpath(_G.dotfiles_dir, "nvim", "langservers")
local servers = require("fsouza.lsp.servers")

servers.start({
  config = {
    name = "jsonnet-language-server",
    cmd = {
      "go",
      "run",
      "-C",
      mod_dir,
      "github.com/grafana/jsonnet-language-server",
      "--lint",
      "--eval-diags"
    }
  },
  opts = {autofmt = true}
})