local function handle(filepath)
  vim.schedule(function()
    os.remove(filepath)
  end)
  vim.cmd.cfile(filepath)
  vim.cmd.copen()
  vim.cmd.cfirst()
end

return {
  handle = handle,
}
