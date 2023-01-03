(import-macros {: mod-invoke} :helpers)

(do
  (vim.keymap.set :t :<esc><esc> "<c-\\><c-n>" {:buffer true :remap false})
  (vim.keymap.set :n :<cr> #(mod-invoke :fsouza.lib.terminal :cr)
                  {:buffer true :remap false})
  (vim.keymap.set :x :<cr> #(mod-invoke :fsouza.lib.terminal :v-cr)
                  {:buffer true :remap false}))
