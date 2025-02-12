local pl_path = require("pl.path")

local function isrel(path, start)
  return not vim.startswith(pl_path.relpath(path, start), "../")
end

local function mkdir(path, recursive, cb)
  local cmd = recursive and { "mkdir", "-p", path } or { "mkdir", path }

  local function handle_result(result)
    if result.code == 1 then
      error(result.stderr)
    else
      cb(path)
    end
  end

  vim.system(cmd, nil, vim.schedule_wrap(handle_result))
end

local mod = { isrel = isrel, mkdir = mkdir }

return setmetatable(mod, {
  __index = function(table, key)
    local value = pl_path[key]
    rawset(table, key, value)
    return value
  end,
})
