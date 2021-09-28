do
  local api = vim.api
  local bufnr = api.nvim_get_current_buf()

  require('fsouza.tablex').foreach(api.nvim_list_wins(), function(winid)
    local winbuf = api.nvim_win_get_buf(winid)
    if winbuf == bufnr then
      require('fsouza.color')['set-popup-winid'](winid)
    end
  end)
end
