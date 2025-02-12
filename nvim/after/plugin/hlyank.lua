local augroup = require("fsouza.lib.nvim-helpers").augroup

augroup("yank_highlight", {
  {
    events = { "TextYankPost" },
    targets = { "*" },
    callback = function()
      vim.highlight.on_yank({
        higroup = "HlYank",
        timeout = 200,
        on_macro = false,
      })
    end,
  },
})
