local terminal = require("fsouza.lib.terminal")
vim.keymap.set("t", "<esc><esc>", "<c-\\><c-n>", { buffer = true, remap = false })
vim.keymap.set("n", "<cr>", terminal.cr, { buffer = true, remap = false })
