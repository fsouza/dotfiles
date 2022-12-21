;; this module exists for efm formatters that are shared across different file
;; types, such as shfmt and prettierd.

(fn get-shfmt [cb]
  (let [path (require :fsouza.pl.path)
        shfmt-path (path.join cache-dir :langservers :bin :shfmt)]
    (cb {:formatCommand (string.format "%s -" shfmt-path) :formatStdin true})))

{: get-shfmt}
