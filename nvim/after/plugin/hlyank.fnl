(let [{: augroup} (require :fsouza.lib.nvim-helpers)]
  (augroup :yank_highlight
           [{:events [:TextYankPost]
             :targets ["*"]
             :callback #(vim.highlight.on_yank {:higroup :HlYank
                                                :timeout 200
                                                :on_macro false})}]))
