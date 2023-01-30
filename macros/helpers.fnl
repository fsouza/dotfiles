(fn reload [mod-name]
  `(do
     (tset package.loaded ,mod-name nil)
     (require ,mod-name)))

(fn mod-invoke [mod fn-name ...]
  `((. (require ,mod) ,fn-name) ,...))

(fn max-col [] 2147483647)

(fn custom-surround [ch val]
  `(tset vim.b ,(.. :surround_ (string.byte ch)) ,val))

{: reload : mod-invoke : max-col : custom-surround}
