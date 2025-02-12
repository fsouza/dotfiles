local augroup = require("fsouza.lib.nvim-helpers").augroup

augroup("fsouza__auto_spell", {
  {
    events = { "FileType" },
    targets = { "changelog", "gitcommit", "help", "markdown", "text" },
    command = "setlocal spell",
  },
})
