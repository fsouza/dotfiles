local bufnr = vim.api.nvim_get_current_buf()
local efm = require("fsouza.lsp.servers.efm")

efm.add(bufnr, "nix", {
  { formatCommand = "nixfmt --filename ${INPUT}", formatStdin = true },
})
