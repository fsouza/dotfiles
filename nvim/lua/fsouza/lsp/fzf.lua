local M = {}

function M.send(items, prompt)
  prompt = prompt .. '：'

  -- import this early to make sure we're properly configured.
  local fzf_files = require('fsouza.fzf-lua').fzf_files

  local config = require('fzf-lua.config')
  local core = require('fzf-lua.core')
  local opts = config.normalize_opts({prompt = prompt; cwd = vim.loop.cwd()}, config.globals.lsp)
  opts.fzf_fn = vim.tbl_map(function(item)
    item = core.make_entry_lcol(opts, item)
    item = core.make_entry_file(opts, item)
    return item
  end, items)
  opts = core.set_fzf_line_args(opts)
  fzf_files(opts)
end

return M
