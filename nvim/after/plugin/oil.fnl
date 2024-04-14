(let [oil (require :oil)]
  (oil.setup {:keymaps {:<C-x> :actions.select_split
                        :<C-v> :actions.select_vsplit
                        :gq :actions.close}
              :view_options {:show_hidden true}})
  (vim.keymap.set :n "-" oil.open))
