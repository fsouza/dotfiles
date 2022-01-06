(do
  (vim.keymap.set "t" "<esc><esc>" "<c-\\><c-n>" {:buffer true :remap false})
  (vim.keymap.set "n"
                  "<cr>"
                  #(let [terminal (require :fsouza.plugin.terminal)]
                     (terminal.cr))
                  {:buffer true
                   :remap false}))
