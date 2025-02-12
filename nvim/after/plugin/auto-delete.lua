local function on_FileChangedShell(opts)
  local buf = opts.buf
  if vim.v.fcs_reason == "deleted" then
    vim.schedule(function()
      vim.cmd.bwipeout({ range = { buf }, bang = true })
    end)
  elseif vim.v.fcs_reason ~= "conflict" then
    vim.v.fcs_choice = "reload"
  end
end

local augroup = require("fsouza.lib.nvim-helpers").augroup
augroup("fsouza__auto_delete", {
  {
    events = { "FileChangedShell" },
    targets = { "*" },
    callback = on_FileChangedShell,
  },
})
