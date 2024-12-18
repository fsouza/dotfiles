(fn wrap-callback [cb]
  (if cb
      (fn [...]
        (cb ...)
        nil)
      nil))

(fn augroup [name commands]
  (let [group (vim.api.nvim_create_augroup name {:clear true})]
    (each [_ {: targets : command : callback : once : events} (ipairs commands)]
      (vim.api.nvim_create_autocmd events
                                   {:pattern targets
                                    : command
                                    :callback (wrap-callback callback)
                                    : group
                                    : once}))))

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
          col-offset (- (string.len (or new-line "")) (string.len orig-line))]
      (vim.api.nvim_win_set_cursor winid
                                   [(math.max lineno 1)
                                    (math.min (math.max 0
                                                        (+ orig-colno
                                                           col-offset))
                                              vim.v.maxcol)]))))

(fn get-visual-selection-range []
  (let [{: mode} (vim.api.nvim_get_mode)
        [_ srow scol _] (vim.fn.getpos ".")
        [_ erow ecol _] (vim.fn.getpos :v)]
    (if (< srow erow) [srow scol erow ecol]
        (if (> srow erow) [erow ecol srow scol]
            (if (<= scol ecol) [srow scol erow ecol] [erow ecol srow scol])))))

(fn get-visual-selection-contents []
  (let [{: mode} (vim.api.nvim_get_mode)]
    (vim.fn.getregion (vim.fn.getpos :v) (vim.fn.getpos ".") {:type mode})))

(fn hash-buffer [bufnr]
  (let [sha1 (require :sha1)
        lines (-> bufnr
                  (vim.api.nvim_buf_get_lines 0 -1 true)
                  (table.concat "\n"))]
    (sha1.sha1 lines)))

{:reset-augroup #(vim.api.nvim_create_augroup $1 {:clear true})
 : augroup
 : once
 : rewrite-wrap
 : get-visual-selection-contents
 : get-visual-selection-range
 : hash-buffer}
