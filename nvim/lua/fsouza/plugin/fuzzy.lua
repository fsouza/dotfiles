local M = {}

function M.find_files(dir)
  require('telescope.builtin').find_files({
    find_command = {'fd'; '--type'; 'f'; '--hidden'; '-E'; '.git'; '-E'; '.hg'; dir or '.'};
  })
end

return M
