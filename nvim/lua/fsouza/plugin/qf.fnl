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

(fn set-from-lines [lines opts]
  (let [opts (if-nil opts {})
        list (load-from-lines lines opts.hook)]
    (vim.fn.setqflist list)
    (when opts.open
      (vim.cmd :copen))
    (when opts.jump-to-first
      (vim.cmd :cfirst))
    (> (length list) 0)))

(fn set-from-contents [content opts]
  (set-from-lines (vim.split content "\n" {:plain true :trimempty true}) opts))

(fn set-from-visual-selection [opts]
  (let [lines (mod-invoke :fsouza.lib.nvim-helpers
                          :get-visual-selection-contents)]
    (set-from-lines lines opts)))

{: set-from-visual-selection : set-from-contents}
