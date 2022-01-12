;; TODO(fsouza): per-language filters. For example, I want to filter out import
;; lines in Python and TypeScript, and things like that.

(fn do-filter [refs]
  (let [tablex (require :fsouza.tablex)
        [lineno _] (vim.api.nvim_win_get_cursor 0)
        lineno (- lineno 1)]
    (tablex.filter refs #(not= $1.range.start.line lineno))))

(fn filter-references [refs]
  (if (vim.tbl_islist refs)
    (do-filter refs)
    refs))

{: filter-references}
