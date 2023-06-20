(fn valid-diagnostic [d]
  (not (vim.startswith d.message
                       "Invalid duplicate class definition of class build")))

{: valid-diagnostic}
