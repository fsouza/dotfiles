local api = vim.api
local vcmd = vim.cmd
local loop = vim.loop

local M = {registry = {}}

local function fzf_dir(directory, cd)
  if cd then
    api.nvim_set_current_dir(directory)
    require('telescope.builtin').find_files()
  else
    require('telescope.builtin').find_files({search_dirs = {directory}})
  end
end

function M.register(command, path)
  M.registry[command] = function(bang)
    local cd = bang == '!'
    loop.fs_stat(path, function(err, stat)
      if err then
        return
      end
      local is_dir = stat.type == 'directory'
      vim.schedule(function()
        if is_dir then
          fzf_dir(path, cd)
        else
          vcmd('edit ' .. path)
        end
      end)
    end)
  end
  vcmd(string.format(
         [[command! -bang %s lua require('fsouza.plugin.shortcut').registry['%s'](vim.fn.expand('<bang>'))]],
         command, command))
end

return M
