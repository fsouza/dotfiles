(import-macros {: mod-invoke : if-nil} :helpers)

(fn handle-action [action cb winid]
  (let [[index _] (vim.api.nvim_win_get_cursor 0)]
    (vim.cmd.wincmd :p)
    (when (vim.api.nvim_win_is_valid winid)
      (vim.api.nvim_win_close winid false))
    (match action
      :abort (cb nil)
      :select (cb index))))

(lambda open [lines cb]
  (let [(winid bufnr) (mod-invoke :fsouza.lib.popup :open
                                  {: lines :type-name :picker :row 1})
        mapping-opts {:buffer bufnr}]
    (vim.api.nvim_win_set_option winid :cursorline true)
    (vim.api.nvim_win_set_option winid :cursorlineopt :both)
    (vim.api.nvim_win_set_option winid :number true)
    (vim.api.nvim_set_current_win winid)
    (mod-invoke :fsouza.lib.nvim-helpers :augroup :fsouza-popup-picker-leave
                [{:events [:WinLeave]
                  :targets [(string.format "<buffer=%d>" bufnr)]
                  :once true
                  :callback #(vim.api.nvim_win_close winid false)}])
    (vim.keymap.set :n :<esc> #(handle-action :abort cb winid) mapping-opts)
    (vim.keymap.set :n :<cr> #(handle-action :select cb winid) mapping-opts)
    (vim.keymap.set :n :<c-n> :<down> {:remap false :buffer bufnr})
    (vim.keymap.set :n :<c-p> :<up> {:remap false :buffer bufnr})))

(lambda ui-select [items opts cb]
  (let [format-item (if-nil (?. opts :format_item) tostring)
        lines (icollect [_ item (ipairs items)]
                (format-item item))]
    (open lines #(if $1
                     (cb (. items $1) $1)
                     (cb nil nil)))))

{: open : ui-select}
