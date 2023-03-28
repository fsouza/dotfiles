(import-macros {: mod-invoke} :helpers)

(fn is-test [fname]
  ;; Starting with Go, but I can add more stuff later.
  (vim.endswith fname :_test.go))

(fn do-filter [refs]
  (let [tablex (require :fsouza.pl.tablex)
        [lineno _] (vim.api.nvim_win_get_cursor 0)
        lineno (- lineno 1)
        refs (tablex.filter refs #(not= $1.range.start.line lineno))]
    (if (is-test (vim.api.nvim_buf_get_name 0))
        refs
        (tablex.for-all refs #(is-test (vim.uri_to_fname $1.uri)) refs
                        (tablex.filter refs #(not (is-test $1.uri)))))))

(fn filter-references [refs]
  (if (vim.tbl_islist refs)
      (if (> (length refs) 1)
          (do-filter refs)
          refs)
      refs))

{: filter-references}
