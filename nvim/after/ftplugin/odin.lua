local servers = require("fsouza.lsp.servers")
local ols = vim.fs.joinpath(_G.cache_dir, "langservers", "ols", "ols")

servers.start({
  config = {
    name = "ols",
    cmd = { ols },
    init_options = {
      enable_format = true,
      enable_hover = true,
      enable_references = true,
    },
  },
  opts = { autofmt = true },
})
