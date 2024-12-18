(fn parse-line [line map]
  (let [col-pattern "^([a-zA-Z0-9/][^:]+):(%d+):(%d+):(.+)"
        line-pattern "^([a-zA-Z0-9/][^:]+):(%d+):(.+)"
        line (vim.trim line)
        (filename lnum col text) (string.match line col-pattern)]
    (if filename
        (map {: filename
              :lnum (tonumber lnum)
              :col (tonumber col)
              : text
              :type :E})
        (let [(filename lnum text) (string.match line line-pattern)]
          (if filename
              (map {: filename :lnum (tonumber lnum) : text :col 1 :type :E})
              nil)))))

(fn load-from-lines [lines map]
  (let [map (or map #$1)]
    (icollect [_ line (ipairs lines)]
      (parse-line line map))))

(fn set-from-lines [lines opts]
  (let [opts (or opts {})
        list (load-from-lines lines opts.map)]
    (vim.fn.setqflist list)
    (when opts.open
      (vim.cmd.copen))
    (when opts.jump-to-first
      (vim.cmd.cfirst))
    (> (length list) 0)))

(fn set-from-contents [content ?opts]
  (-> content
      (vim.split "\n" {:plain true :trimempty true})
      (set-from-lines ?opts)))

(fn set-from-visual-selection [?opts]
  (let [nvim-helpers (require :fsouza.lib.nvim-helpers)
        lines (nvim-helpers.get-visual-selection-contents)]
    (set-from-lines lines ?opts)))

{: set-from-visual-selection : set-from-contents}
