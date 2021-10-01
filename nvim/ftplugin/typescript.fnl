(let [bufnr (vim.api.nvim_get_current_buf)]
  (vim.api.nvim_buf_set_option bufnr "formatexpr" "")
  (vim.api.nvim_buf_set_option bufnr "formatprg" ""))
