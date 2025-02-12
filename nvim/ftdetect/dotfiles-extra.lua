local augroup = require("fsouza.lib.nvim-helpers").augroup

augroup("fsouza__ftdetect__dotfiles__extra", {
  {
    events = {"BufRead"},
    targets = {vim.fs.joinpath(_G.dotfiles_dir, "extra", "*")},
    callback = function(opts)
      if vim.bo[opts.buf] then
        vim.bo[opts.buf].filetype = "zsh"
      end
    end
  }
})