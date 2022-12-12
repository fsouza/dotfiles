(import-macros {: if-nil : send-esc : max-col : mod-invoke} :helpers)

(fn wrap-callback [cb]
  (if (not= cb nil)
      #(do
         (cb)
         nil)
      nil))

(lambda augroup [name commands]
  (let [group (vim.api.nvim_create_augroup name {:clear true})]
    (each [_ c (ipairs commands)]
      (vim.api.nvim_create_autocmd c.events
                                   {:pattern c.targets
                                    :command c.command
                                    :callback (wrap-callback c.callback)
                                    : group
                                    :once c.once}))))

(lambda once [f]
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
(lambda rewrite-wrap [f]
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
                                   [(math.max lineno 1)
                                    (math.min (math.max 0
                                                        (+ orig-colno
                                                           col-offset))
                                              (max-col))]))))

(lambda get-visual-selection-range []
  (fn from-markers []
    (let [[_ srow scol _] (vim.fn.getpos "'<")
          [_ erow ecol _] (vim.fn.getpos "'>")]
      [srow scol erow ecol]))

  (fn from-current [mode]
    (let [[_ srow scol _] (vim.fn.getpos ".")
          [_ erow ecol _] (vim.fn.getpos :v)]
      (send-esc)
      (if (= mode :V) [srow 0 erow (max-col)] [srow scol erow ecol])))

  (let [{: mode} (vim.api.nvim_get_mode)
        [srow scol erow ecol] (if (or (= mode :v) (= mode :V))
                                  (from-current mode)
                                  (from-markers))]
    (if (< srow erow) [srow scol erow ecol]
        (if (> srow erow) [erow ecol srow scol]
            (if (<= scol ecol) [srow scol erow ecol] [erow ecol srow scol])))))

(lambda get-visual-selection-contents []
  (let [[srow scol erow ecol] (get-visual-selection-range)
        lines (vim.api.nvim_buf_get_text 0 (- srow 1) (- scol 1) (- erow 1)
                                         ecol {})]
    lines))

(lambda extract-luv-error [?err]
  (if (= ?err nil)
      nil
      (. (vim.split ?err ":" {:plain true :trimempty true}) 1)))

(lambda hash-buffer [bufnr]
  (let [lines (-> bufnr
                  (vim.api.nvim_buf_get_lines 0 -1 true)
                  (table.concat "\n"))]
    (mod-invoke :lsha2 :hash256 lines)))

(lambda keymap-repeat [lhs cb opts]
  (vim.keymap.set :n lhs
                  #(do
                     (cb)
                     (vim.api.nvim_call_function "repeat#set" [lhs]))
                  opts))

{:reset-augroup #(vim.api.nvim_create_augroup $1 {:clear true})
 : augroup
 : once
 : rewrite-wrap
 : get-visual-selection-contents
 : get-visual-selection-range
 : extract-luv-error
 : hash-buffer
 : keymap-repeat}
