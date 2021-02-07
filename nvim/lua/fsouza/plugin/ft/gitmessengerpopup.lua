local api = vim.api

return function(bufnr)
  for _, winid in ipairs(api.nvim_list_wins()) do
    local winbuf = api.nvim_win_get_buf(winid)
    if winbuf == bufnr then
      require('fsouza.color').set_popup_winid(winid)
    end
  end
end
