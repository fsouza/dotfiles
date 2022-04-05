(import-macros {: mod-invoke} :helpers)

(var colors-name nil)

(fn enable []
  (when (not colors-name)
    (set colors-name vim.g.colors_name)
    (vim.cmd "colorscheme solarized")
    (vim.api.nvim_set_hl 0 :WinSeparator {:fg "#839496"})))

(fn disable []
  (when colors-name
    (vim.cmd (string.format "colorscheme %s" colors-name))
    (set colors-name nil)))

{: enable : disable}
