(import-macros {: if-nil} :helpers)

(fn min [x y]
  (if (< x y)
      x
      y))

(fn max [x y]
  (if (> x y)
      x
      y))

(fn close-others [win-var-identifier]
  (each [_ winid (ipairs (vim.api.nvim_list_wins))]
    (when (pcall vim.api.nvim_win_get_var winid win-var-identifier)
      (vim.api.nvim_win_close winid true))))

(fn open [opts]
  (let [{: lines : type-name : markdown : min-width : max-width : wrap} opts
        longest (* 2 (accumulate [longest 0 _ line (ipairs lines)]
                       (max longest (length line))))
        min-width (if-nil min-width 50)
        max-width (if-nil max-width (* 3 min-width))
        bufnr (vim.api.nvim_create_buf false true)
        win-var-identifier (string.format "fsouza__popup-%s" type-name)
        width (min (max longest min-width) max-width)
        height (length lines)
        col (if opts.right-col
                (- opts.right-col width)
                (if-nil opts.col 0))
        win-opts {:relative (if-nil opts.relative :cursor)
                  : width
                  : height
                  : col
                  :row (if-nil opts.row 0)
                  :style :minimal}]
    (if markdown
        (vim.lsp.util.stylize_markdown bufnr lines
                                       {: width : height :separator true})
        (vim.api.nvim_buf_set_lines bufnr 0 -1 true lines))
    (close-others win-var-identifier)
    (let [winid (vim.api.nvim_open_win bufnr false win-opts)
          helpers (require :fsouza.lib.nvim-helpers)]
      (vim.api.nvim_buf_set_option bufnr :readonly true)
      (vim.api.nvim_buf_set_option bufnr :modifiable false)
      (vim.api.nvim_win_set_option winid :wrap (= wrap true))
      (vim.api.nvim_win_set_var winid win-var-identifier true)
      (values winid bufnr))))

{: open}
