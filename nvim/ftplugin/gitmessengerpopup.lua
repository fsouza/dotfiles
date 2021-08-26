do
  local api = vim.api
  local bufnr = api.nvim_get_current_buf()

  for _, winid in ipairs(api.nvim_list_wins()) do
    local winbuf = api.nvim_win_get_buf(winid)
    if winbuf == bufnr then
      require('fsouza.color').set_popup_winid(winid)
    end
  end
end
