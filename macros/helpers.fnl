(fn mod-invoke [mod fn-name ...]
  `((. (require ,mod) ,fn-name) ,...))

{: mod-invoke}
