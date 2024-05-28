(fn process-stdout [content]
  (let [lines (vim.split content "\n" {:plain true :trimempty true})
        uniq-lines (accumulate [uniq-lines {} _ line (ipairs lines)]
                     (let [line (vim.trim line)]
                       (tset uniq-lines line true)
                       uniq-lines))]
    (vim.tbl_keys uniq-lines)))

(fn find-pos [line]
  (string.find line "[^%s]"))

(fn complete []
  (let [current-line (vim.api.nvim_get_current_line)
        compl-pos (find-pos current-line)
        current-line (vim.trim current-line)]
    (when current-line
      (vim.system [:rg
                   :--case-sensitive
                   :--fixed-strings
                   :--no-line-number
                   :--no-filename
                   :--no-heading
                   :--hidden
                   "--"
                   current-line
                   "."] nil
                  (vim.schedule_wrap #(when (= $1.code 0)
                                        (->> $1.stdout
                                             (process-stdout)
                                             (vim.fn.complete compl-pos)))))))
  "")

(let [keybind :<c-x><c-n>]
  (vim.keymap.set :i keybind complete {:remap false}))
