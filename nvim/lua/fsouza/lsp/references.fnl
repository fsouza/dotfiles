(import-macros {: mod-invoke} :helpers)

(fn do-filter [refs]
  (let [[lineno _] (vim.api.nvim_win_get_cursor 0)
        lineno (- lineno 1)]
    (mod-invoke :fsouza.pl.tablex :filter refs
                #(not= $1.range.start.line lineno))))

(fn filter-references [refs]
  (if (vim.tbl_islist refs)
      (if (> (length refs) 1)
          (do-filter refs)
          refs)
      refs))

{: filter-references}
