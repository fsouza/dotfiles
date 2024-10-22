(local test-checkers {})

(fn is-test [fname]
  (let [path (require :fsouza.lib.path)
        ext (path.extension fname)
        ext-checkers (or (. test-checkers ext) {})]
    (-> ext-checkers
        (pairs)
        (vim.iter)
        (: :any #($2 fname)))))

(fn do-filter [items]
  (let [[lineno _] (vim.api.nvim_win_get_cursor 0)
        items (-> items
                  (vim.iter)
                  (: :filter #(not= $1.lnum lineno)))]
    (if (is-test (vim.api.nvim_buf_get_name 0)) (items:totable)
        (let [items2 (vim.deepcopy items)]
          (if (items2:all #(is-test $1.filename))
              (items:totable)
              (-> items
                  (: :filter #(not (is-test $1.filename)))
                  (: :totable)))))))

(fn filter-references [items]
  (if (vim.islist items)
      (if (> (length items) 1)
          (do-filter items)
          items)
      items))

(fn register-test-checker [ext name checker]
  (let [ext-checkers (or (. test-checkers ext) {})]
    (tset ext-checkers name checker)
    (tset test-checkers ext ext-checkers)))

(fn on-list [list]
  (let [fuzzy (require :fsouza.lib.fuzzy)]
    (tset list :items (filter-references list.items))
    (fuzzy.lsp-on-list list)))

{: register-test-checker : on-list}
