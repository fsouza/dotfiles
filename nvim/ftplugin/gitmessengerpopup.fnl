(let [bufnr (vim.api.nvim_get_current_buf)]
  (each [_ winid (ipairs (vim.api.nvim_list_wins))]
    (let [winbuf (vim.api.nvim_win_get_buf winid)
          color (require "fsouza.color")]
      (when (= winbuf bufnr)
        (color.set-popup-winid winid)))))
