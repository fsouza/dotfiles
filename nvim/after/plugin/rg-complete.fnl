(import-macros {: mod-invoke} :helpers)

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
      (mod-invoke :fsouza.lib.cmd :run :rg
                  {:args [:--case-sensitive
                          :--fixed-strings
                          :--no-line-number
                          :--no-filename
                          :--no-heading
                          :--hidden
                          "--"
                          current-line
                          "."]} nil
                  (fn [result]
                    (when (= result.exit-status 0)
                      (->> result.stdout
                           (process-stdout)
                           (vim.fn.complete compl-pos)))))))
  "")

(let [keybind :<c-x><c-n>]
  (vim.keymap.set :i keybind complete {:remap false}))
