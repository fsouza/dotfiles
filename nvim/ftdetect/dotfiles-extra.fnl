(let [{: augroup} (require :fsouza.lib.nvim-helpers)]
  (augroup :fsouza__ftdetect__dotfiles__extra
           [{:events [:BufRead]
             :targets [(vim.fs.joinpath _G.dotfiles-dir :extra "*")]
             :callback #(tset (?. vim :bo $1.buf) :filetype :zsh)}]))
