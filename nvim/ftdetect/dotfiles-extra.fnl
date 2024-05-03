(import-macros {: mod-invoke} :helpers)

(mod-invoke :fsouza.lib.nvim-helpers :augroup
            :fsouza__ftdetect__dotfiles__extra
            [{:events [:BufRead]
              :targets [(vim.fs.joinpath _G.dotfiles-dir :extra "*")]
              :callback #(vim.api.nvim_buf_set_option $1.buf :filetype :zsh)}])
