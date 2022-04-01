(import-macros {: mod-invoke} :helpers)

(fn process-stdout [content]
  (let [lines (vim.split content "\n" {:plain true :trimempty true})
        uniq-lines (accumulate [uniq-lines {} _ line (ipairs lines)]
                     (let [line (vim.trim line)]
                       (tset uniq-lines line true)
                       uniq-lines))]
    (vim.tbl_keys uniq-lines)))

(fn complete []
  (let [current-line (vim.trim (vim.api.nvim_get_current_line))]
    (when current-line
      (mod-invoke :fsouza.lib.cmd :run :rg
                  {:args [:--case-sensitive
                          :--fixed-strings
                          current-line
                          :--no-line-number
                          :--no-filename
                          :--no-heading
                          "."]} nil
                  (fn [result]
                    (when (= result.exit-status 0)
                      (->> result.stdout
                           (process-stdout)
                           (vim.fn.complete 1)))))))
  "")

(fn setup [keybind]
  (vim.keymap.set :i keybind complete {:remap false}))

{: setup}
