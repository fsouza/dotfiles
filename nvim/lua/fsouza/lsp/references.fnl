(import-macros {: mod-invoke} :helpers)

(local test-checkers {})

(fn is-test [fname]
  (let [ext (mod-invoke :fsouza.pl.path :extension fname)
        ext-checkers (or (. test-checkers ext) {})]
    (mod-invoke :fsouza.pl.tablex :exists ext-checkers #($1 fname))))

(fn do-filter [refs]
  (let [tablex (require :fsouza.pl.tablex)
        [lineno _] (vim.api.nvim_win_get_cursor 0)
        lineno (- lineno 1)
        refs (tablex.filter refs #(not= $1.range.start.line lineno))]
    (if (is-test (vim.api.nvim_buf_get_name 0)) refs
        (tablex.for-all refs #(is-test (vim.uri_to_fname $1.uri))) refs
        (tablex.filter refs #(not (is-test (vim.uri_to_fname $1.uri)))))))

(fn filter-references [refs]
  (if (vim.tbl_islist refs)
      (if (> (length refs) 1)
          (do-filter refs)
          refs)
      refs))

(fn register-test-checker [ext name checker]
  (let [ext-checkers (or (. test-checkers ext) {})]
    (tset ext-checkers name checker)
    (tset test-checkers ext ext-checkers)))

{: filter-references : register-test-checker}
