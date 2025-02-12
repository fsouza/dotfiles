local servers = require("fsouza.lsp.servers")
vim.b["surround_" .. string.byte("l")] = "[\r](\001url: \001)"
servers.start({
  config = {
    name = "markdown-language-server",
    cmd = {"vscode-markdown-language-server", "--stdio"}
  }
})