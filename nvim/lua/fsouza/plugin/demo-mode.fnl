(import-macros {: mod-invoke} :helpers)

(var colors-name nil)

(fn enable []
  (when (not colors-name)
    (set colors-name vim.g.colors_name)
    (tset vim.o :background :light)
    (vim.cmd.colorscheme :rose-pine)))

(fn disable []
  (when colors-name
    (vim.cmd.colorscheme colors-name)
    (set colors-name nil)))

{: enable : disable}
