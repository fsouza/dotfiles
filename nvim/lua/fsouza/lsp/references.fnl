(import-macros {: mod-invoke} :helpers)

(local test-checkers {})

(fn is-test [fname]
  (let [ext (mod-invoke :fsouza.lib.path :extension fname)
        ext-checkers (or (. test-checkers ext) {})]
    (-> ext-checkers
        (pairs)
        (vim.iter)
        (: :any #($2 fname)))))

(fn do-filter [refs]
  (let [[lineno _] (vim.api.nvim_win_get_cursor 0)
        lineno (- lineno 1)
        refs (-> refs
                 (vim.iter)
                 (: :filter #(not= $1.range.start.line lineno)))]
    (if (is-test (vim.api.nvim_buf_get_name 0)) (refs:totable)
        (let [refs2 (vim.deepcopy refs)]
          (if (refs2:all #(is-test (vim.uri_to_fname $1.uri)))
              (refs:totable)
              (-> refs
                  (: :filter #(not (is-test (vim.uri_to_fname $1.uri))))
                  (: :totable)))))))

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
