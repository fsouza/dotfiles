local api = vim.api
local vcmd = vim.cmd
local loop = vim.loop

-- workaround for fzf loading issue. I should just switch to telescope.nvim.
local _ = vim.fn['fzf#run']

local M = {}

local function fzf_dir(directory, cd)
  if cd then
    api.nvim_set_current_dir(directory)
    vcmd('FzfFiles')
  else
    vcmd('FzfFiles ' .. directory)
  end
end

function M.register(command, path, cd)
  M[command] = function()
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
  vcmd(string.format([[command! %s lua require('fsouza.plugin.shortcut')['%s']()]], command,
                     command))
end

return M
