(fn handle-selection [cb winid]
  (let [index (. (vim.api.nvim_win_get_cursor 0) 1)]
    (vim.cmd "wincmd p")
    (when (vim.api.nvim_win_is_valid winid)
      (vim.api.nvim_win_close winid false))
    (cb index)))

(fn open [lines cb]
  (let [popup (require :fsouza.lib.popup)
        (winid bufnr) (popup.open {: lines :type-name :picker :row 1})
        helpers (require :fsouza.lib.nvim-helpers)
        mapping-opts {:buffer bufnr}]
    (vim.api.nvim_win_set_option winid :cursorline true)
    (vim.api.nvim_win_set_option winid :cursorlineopt :both)
    (vim.api.nvim_win_set_option winid :number true)
    (vim.api.nvim_set_current_win winid)
    (helpers.augroup :fsouza-popup-picker-leave
                     [{:events [:WinLeave]
                       :targets [(string.format "<buffer=%d>" bufnr)]
                       :once true
                       :callback (partial vim.api.nvim_win_close winid false)}])
    (vim.keymap.set :n :<esc> #(vim.api.nvim_win_close winid false)
                    mapping-opts)
    (vim.keymap.set :n :<cr> #(handle-selection cb winid) mapping-opts)
    (vim.keymap.set :n :<c-n> :<down> {:remap false :buffer bufnr})
    (vim.keymap.set :n :<c-p> :<up> {:remap false :buffer bufnr})))

{: open}
