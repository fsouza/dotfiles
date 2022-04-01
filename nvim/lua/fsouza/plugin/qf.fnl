(import-macros {: if-nil : mod-invoke} :helpers)

(fn parse-line [line hook]
  (let [col-pattern "^([a-zA-Z0-9/][^:]+):(%d+):(%d+):(.+)"
        line-pattern "^([a-zA-Z0-9/][^:]+):(%d+):(.+)"
        line (vim.trim line)
        (filename lnum col text) (string.match line col-pattern)]
    (if filename
        (hook {: filename
               :lnum (tonumber lnum)
               :col (tonumber col)
               : text
               :type :E})
        (let [(filename lnum text) (string.match line line-pattern)]
          (if filename
              (hook {: filename :lnum (tonumber lnum) : text :col 1 :type :E})
              nil)))))

(fn load-from-lines [lines hook]
  (let [hook (if-nil hook #$1)]
    (icollect [_ line (ipairs lines)]
      (parse-line line hook))))

(fn set-from-lines [lines hook]
  (let [list (load-from-lines lines hook)]
    (vim.fn.setqflist list)
    (> (length list) 0)))

(fn set-from-contents [content hook]
  (set-from-lines (vim.split content "\n" {:plain true :trimempty true}) hook))

(fn set-from-visual-selection [hook]
  (let [lines (mod-invoke :fsouza.lib.nvim-helpers
                          :get-visual-selection-contents)]
    (set-from-lines lines hook)))

{: set-from-visual-selection : set-from-contents}
