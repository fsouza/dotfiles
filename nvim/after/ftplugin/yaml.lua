local servers = require("fsouza.lsp.servers")
servers.start({
  config = {
    name = "yaml-language-server",
    cmd = {"yaml-language-server", "--stdio"},
    settings = {
      yaml = {
        keyOrdering = false,
        schemaStore = {enable = true}
      }
    }
  }
})