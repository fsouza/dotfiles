local function handle_action(action, cb, winid)
  local index, _ = unpack(vim.api.nvim_win_get_cursor(0))
  vim.cmd.wincmd("p")

  if vim.api.nvim_win_is_valid(winid) then
    vim.api.nvim_win_close(winid, false)
  end

  if action == "abort" then
    cb(nil)
  elseif action == "select" then
    cb(index)
  end
end

local function open(lines, cb)
  local popup = require("fsouza.lib.popup")
  local winid, bufnr = popup.open({ lines = lines, type_name = "picker", row = 1 })
  local mapping_opts = { buffer = bufnr }
  local augroup = require("fsouza.lib.nvim-helpers").augroup

  vim.wo[winid].cursorline = true
  vim.wo[winid].cursorlineopt = "both"
  vim.wo[winid].number = true

  vim.api.nvim_set_current_win(winid)

  augroup("fsouza-popup-picker-leave", {
    {
      events = { "WinLeave" },
      targets = { string.format("<buffer=%d>", bufnr) },
      once = true,
      callback = function()
        vim.api.nvim_win_close(winid, false)
      end,
    },
  })

  vim.keymap.set("n", "<esc>", function()
    handle_action("abort", cb, winid)
  end, mapping_opts)

  vim.keymap.set("n", "<cr>", function()
    handle_action("select", cb, winid)
  end, mapping_opts)

  vim.keymap.set("n", "<c-n>", "<down>", { remap = false, buffer = bufnr })

  vim.keymap.set("n", "<c-p>", "<up>", { remap = false, buffer = bufnr })
end

local function ui_select(items, opts, cb)
  local format_item = opts and opts.format_item or tostring
  local lines = {}

  for _, item in ipairs(items) do
    table.insert(lines, format_item(item))
  end

  open(lines, function(index)
    if index then
      cb(items[index], index)
    else
      cb(nil, nil)
    end
  end)
end

return {
  open = open,
  ui_select = ui_select,
}
