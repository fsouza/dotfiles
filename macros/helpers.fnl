(fn reload [mod-name]
  `(do
     (tset package.loaded ,mod-name nil)
     (require ,mod-name)))

(fn mod-invoke [mod fn-name ...]
  `((. (require ,mod) ,fn-name) ,...))

(fn max-col []
  2147483647)

{: reload : mod-invoke : max-col}
