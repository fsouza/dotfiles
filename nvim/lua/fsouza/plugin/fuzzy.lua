local M = {}

function M.find_files(dir)
  require('telescope.builtin').find_files({
    find_command = {'fd'; '--type'; 'f'; '--hidden'; '-E'; '.git'; '-E'; '.hg'; '.'; dir or '.'};
  })
end

function M.grep()
  local search = vim.fn.input([[rg：]])
  if search ~= '' then
    require('telescope.builtin').grep_string({search = search; use_regex = true})
  end
end

function M.grep_visual()
  local search = require('fsouza.lib.nvim_helpers').visual_selection()
  if string.find(search, '\n') then
    error('only single line selections are supported')
  end

  if search ~= '' then
    require('telescope.builtin').grep_string({search = search})
  end
end

return M
