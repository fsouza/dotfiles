(import-macros {: mod-invoke} :helpers)

(var colors-name nil)

(fn enable []
  (when (not colors-name)
    (set colors-name vim.g.colors_name)
    (vim.cmd "colorscheme solarized")
    (vim.cmd "highlight WinSeparator gui=NONE guibg=NONE guifg=#839496")))

(fn disable []
  (when colors-name
    (vim.cmd (string.format "colorscheme %s" colors-name))
    (set colors-name nil)))

{: enable : disable}
