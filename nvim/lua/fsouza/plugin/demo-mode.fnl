(import-macros {: mod-invoke} :helpers)

(var colors-name nil)

(fn enable []
  (when (not colors-name)
    (set colors-name vim.g.colors_name)
    (vim.cmd "colorscheme solarized")
    (vim.cmd "highlight WinSeparator gui=NONE guibg=NONE guifg=#839496")
    (mod-invoke :fsouza.lib.nvim-helpers :augroup :fsouza-demo-mode
                [{:events [:User]
                  :targets [:PluginReady]
                  :once true
                  :callback #(let [feline (require :feline)]
                               (feline.add_theme :solarized
                                                 {:bg "#eee8d5"
                                                  :fg "#839496"
                                                  :error "#990000"
                                                  :warning "#a36d00"})
                               (feline.use_theme :solarized))}])))

(fn disable []
  (when colors-name
    (vim.cmd (string.format "colorscheme %s" colors-name))
    (set colors-name nil)
    (let [feline (require :feline)]
      (feline.use_theme :none))))

{: enable : disable}
