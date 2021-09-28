do
  local api = vim.api
  local bufnr = api.nvim_get_current_buf()

  api.nvim_buf_set_option(bufnr, "formatexpr", "")
  api.nvim_buf_set_option(bufnr, "formatprg", "")
end
