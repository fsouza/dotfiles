local M = {}

local loop = vim.loop

-- checks if path is a directory and calls cb with the result (true/false).
function M.check_directory(path: string, cb: function(boolean))
  loop.fs_stat(path, function(err: string, stat: LoopStat)
    if err then
      cb(false)
      return
    end
    cb(stat.type == 'directory')
  end)
end

return M
