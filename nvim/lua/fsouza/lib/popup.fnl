(fn find-other [win-var-identifier]
  (let [winids (icollect [_ winid (ipairs (vim.api.nvim_list_wins))]
                 (when (pcall vim.api.nvim_win_get_var winid win-var-identifier)
                   winid))]
    (assert (<= (length winids) 1))
    (. winids 1)))

(fn set-content [bufnr lines opts]
  (do
    (vim.api.nvim_set_option_value :readonly false {:buf bufnr})
    (vim.api.nvim_set_option_value :modifiable true {:buf bufnr})
    (let [{: markdown : width : height} opts]
      (if markdown
          (vim.lsp.util.stylize_markdown bufnr lines
                                         {: width : height :separator true})
          (vim.api.nvim_buf_set_lines bufnr 0 -1 true lines)))
    (vim.api.nvim_set_option_value :readonly true {:buf bufnr})
    (vim.api.nvim_set_option_value :modifiable false {:buf bufnr})))

(fn update-existing [winid lines opts]
  (let [bufnr (vim.api.nvim_win_get_buf winid)]
    (set-content bufnr lines opts)
    (vim.api.nvim_win_set_width winid opts.width)
    (vim.api.nvim_win_set_height winid opts.height)
    (values winid bufnr)))

(fn do-open [lines opts]
  (let [bufnr (vim.api.nvim_create_buf false true)
        {: win-opts : wrap : win-var-identifier : markdown} opts
        winid (vim.api.nvim_open_win bufnr false win-opts)]
    (set-content bufnr lines
                 {: markdown :width win-opts.width :height win-opts.height})
    (vim.api.nvim_win_set_option winid :wrap (= wrap true))
    (vim.api.nvim_win_set_option winid :winhighlight
                                 "Normal:PopupNormal,CursorLineNr:PopupCursorLineNr,CursorLine:PopupCursorLine")
    (vim.api.nvim_win_set_var winid win-var-identifier true)
    (values winid bufnr)))

(lambda open [opts]
  (let [{: lines
         : type-name
         : markdown
         : min-width
         : max-width
         : wrap
         : update-if-exists} opts
        longest (* 2 (accumulate [longest 0 _ line (ipairs lines)]
                       (math.max longest (length line))))
        min-width (or min-width 50)
        max-width (or max-width (* 3 min-width))
        win-var-identifier (string.format "fsouza__popup-%s" type-name)
        width (math.min (math.max longest min-width) max-width)
        height (length lines)
        col (if opts.right-col
                (- opts.right-col width)
                (or opts.col 0))
        win-opts {:relative (or opts.relative :cursor)
                  : width
                  : height
                  : col
                  :row (or opts.row 0)
                  :style :minimal}]
    (let [other (find-other win-var-identifier)]
      (if other
          (if update-if-exists
              (update-existing other lines {: markdown : width : height})
              (do
                (vim.api.nvim_win_close other true)
                (do-open lines {: win-opts
                                : wrap
                                : win-var-identifier
                                : markdown})))
          (do-open lines {: win-opts : wrap : win-var-identifier : markdown})))))

{: open}
