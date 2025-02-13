local function isrel(path, start)
  start = start or vim.uv.cwd()
  return vim.fs.relpath(start, path) ~= nil
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

local function splitext(p)
  local i = #p
  local ch = p:sub(i, i)
  while i > 0 and ch ~= "." do
    if ch == "/" then
      return p, ""
    end
    i = i - 1
    ch = p:sub(i, i)
  end
  if i == 0 then
    return p, ""
  else
    return p:sub(1, i - 1), p:sub(i)
  end
end

local function extension(p)
  local _, ext = splitext(p)
  return ext
end

return { extension = extension, isrel = isrel, mkdir = mkdir, splitext = splitext }
