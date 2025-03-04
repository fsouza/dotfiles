local servers = require("fsouza.lsp.servers")
servers.start({
  config = {
    name = "rust-analyzer",
    cmd = { vim.fs.joinpath(_G.cache_dir, "langservers", "bin", "rust-analyzer") },
    settings = {
      ["rust-analyzer"] = {
        checkOnSave = {
          command = "clippy",
        },
        cargo = {
          extraArgs = { "--offline" },
        },
      },
    },
    find_root_dir = function()
      return servers.patterns_with_fallback({ "Cargo.toml" })
    end,
  },
  opts = { autofmt = true },
})
