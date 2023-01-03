(import-macros {: mod-invoke} :helpers)

(mod-invoke :fsouza.lib.nvim-helpers :augroup :yank_highlight
            [{:events [:TextYankPost]
              :targets ["*"]
              :callback #(mod-invoke :vim.highlight :on_yank
                                     {:higroup :HlYank
                                      :timeout 200
                                      :on_macro false})}])
