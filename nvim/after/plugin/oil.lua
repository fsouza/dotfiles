local oil = require("oil")
oil.setup({
  keymaps = { ["<C-x>"] = "actions.select_split", gq = "actions.close" },
  skip_confirm_for_simple_edits = true,
  view_options = { show_hidden = true },
})

vim.keymap.set("n", "-", function()
  if vim.bo.filetype ~= "fugitiveblame" then
    oil.open()
  end
end)
