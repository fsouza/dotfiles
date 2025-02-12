local function fzf_dir(directory, cd)
  local fuzzy = require("fsouza.lib.fuzzy")

  if cd then
    vim.api.nvim_set_current_dir(directory)
    fuzzy.files()
  else
    fuzzy.files({ cwd = directory })
  end
end

local function make_callback(path)
  return function(args)
    local bang = args.bang

    vim.uv.fs_stat(path, function(err, stat)
      if not err then
        local is_dir = stat.type == "directory"
        vim.schedule(function()
          if is_dir then
            fzf_dir(path, bang)
          else
            vim.cmd.edit(path)
          end
        end)
      end
    end)
  end
end

local function register(command, path)
  vim.api.nvim_create_user_command(command, make_callback(path), { force = true, bang = true })
end

return {
  register = register,
}
