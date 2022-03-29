(import-macros {: if-nil : send-esc : max-col} :helpers)

(fn wrap-callback [cb]
  (if (not= cb nil)
      #(do
         (cb)
         nil)
      nil))

(fn augroup [name commands]
  (let [group (vim.api.nvim_create_augroup name {:clear true})]
    (each [_ c (ipairs commands)]
      (vim.api.nvim_create_autocmd c.events
                                   {:pattern c.targets
                                    :command c.command
                                    :callback (wrap-callback c.callback)
                                    : group
                                    :once c.once}))))

(fn once [f]
  (var result nil)
  (var called false)
  (fn [...]
    (when (not called)
      (set called true)
      (set result (f ...))
      result)
    result))

;; Provides a wrapper to a function that rewrites the current buffer, and does
;; a best effort to restore the cursor position.
(fn rewrite-wrap [f]
  (let [winid (vim.api.nvim_get_current_win)
        bufnr (vim.api.nvim_get_current_buf)
        [orig-lineno orig-colno] (vim.api.nvim_win_get_cursor winid)
        [orig-line] (vim.api.nvim_buf_get_lines bufnr (- orig-lineno 1)
                                                orig-lineno true)
        orig-nlines (vim.api.nvim_buf_line_count bufnr)]
    (f)
    (let [line-offset (- (vim.api.nvim_buf_line_count bufnr) orig-nlines)
          lineno (+ orig-lineno line-offset)
          [new-line] (vim.api.nvim_buf_get_lines bufnr (- lineno 1) lineno true)
          col-offset (- (string.len (if-nil new-line ""))
                        (string.len orig-line))]
      (vim.api.nvim_win_set_cursor winid
                                   [lineno
                                    (math.min (math.max 0
                                                        (+ orig-colno
                                                           col-offset))
                                              (max-col))]))))

(fn get-visual-selection-range []
  (fn from-markers []
    (let [[_ srow scol _] (vim.fn.getpos "'<")
          [_ erow ecol _] (vim.fn.getpos "'>")]
      [srow scol erow ecol]))

  (fn from-current [mode]
    (let [[_ srow scol _] (vim.fn.getpos ".")
          [_ erow ecol _] (vim.fn.getpos :v)]
      (send-esc)
      (if (= mode :V) [srow 0 erow (max-col)] [srow scol erow ecol])))

  (let [mode (vim.fn.mode)
        [srow scol erow ecol] (if (or (= mode :v) (= mode :V))
                                  (from-current mode)
                                  (from-markers))]
    (if (< srow erow) [srow scol erow ecol]
        (if (> srow erow) [erow ecol srow scol]
            (if (<= scol ecol) [srow scol erow ecol] [erow ecol srow scol])))))

(fn get-visual-selection-contents []
  (let [[srow scol erow ecol] (get-visual-selection-range)
        lines (vim.api.nvim_buf_get_lines 0 (- srow 1) erow true)
        nlines (length lines)
        eline (+ 1 (- erow srow))]
    (tset lines eline (string.sub (. lines eline) 1 ecol))
    (tset lines 1 (string.sub (. lines 1) scol))
    lines))

{:reset-augroup #(vim.api.nvim_create_augroup $1 {:clear true})
 : augroup
 : once
 : rewrite-wrap
 : get-visual-selection-contents
 : get-visual-selection-range}
