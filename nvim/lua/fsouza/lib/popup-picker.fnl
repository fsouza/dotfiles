(fn handle-selection [mod winid]
  (let [index (. (vim.api.nvim_win_get_cursor 0) 1)
        {: cb} mod]
    (vim.cmd "wincmd p")
    (vim.api.nvim_win_close winid false)
    (cb index)))

(fn open [mod lines cb]
  (let [popup (require :fsouza.lib.popup)
        (winid bufnr) (popup.open {:lines lines
                                   :type-name "picker"
                                   :enter true
                                   :row 1})
        helpers (require :fsouza.lib.nvim-helpers)]

    (tset mod :cb cb)

    (vim.api.nvim_win_set_option winid :cursorline true)
    (vim.api.nvim_win_set_option winid :cursorlineopt "both")
    (vim.api.nvim_win_set_option winid :number true)

    (helpers.create-mappings {:n [{:lhs "<esc>"
                                    :rhs (helpers.fn-map (partial vim.api.nvim_win_close winid false))}
                                  {:lhs "<cr>"
                                    :rhs (helpers.fn-map (partial handle-selection mod winid))}
                                  {:lhs "<c-n>"
                                    :rhs "<down>"
                                    :opts {:noremap true}}
                                  {:lhs "<c-p>"
                                    :rhs "<up>"
                                    :opts {:noremap true}}]} bufnr)))

(let [mod {:cb nil}]
  {:open (partial open mod)})
