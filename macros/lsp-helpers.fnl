(fn get-cache-path [...]
  `(vim.fs.joinpath _G.cache-dir :langservers ,...))

(fn get-cache-cmd [cmd]
  (get-cache-path :bin cmd))

{: get-cache-cmd}
