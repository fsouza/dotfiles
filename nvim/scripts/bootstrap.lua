local vfn = vim.fn
local loop = vim.loop

local second_ms = 1000
local minute_ms = 60 * second_ms

local cache_dir = vfn.stdpath('cache')
local site_dir = string.format('%s/site', vfn.stdpath('data'))

local function execute(pat, ...)
  local cmd = string.format(pat, ...)
  local status = os.execute(cmd)
  if status ~= 0 then
    error(string.format(
            '================\ncommand "%s" exitted with status %d\n================\n', cmd,
            status))
  end
end

local function ensure_virtualenv()
  local venv_dir = cache_dir .. '/venv'
  if not loop.fs_stat(venv_dir) then
    execute([[python3 -m venv %s]], venv_dir)
  end
  execute([[%s/venv/bin/pip install --upgrade -r ./langservers/requirements.txt]], cache_dir)
  return venv_dir
end

local function setup_langservers()
  execute([[./langservers/setup.sh %s/langservers]], cache_dir)
end

local function install_autoload_plugins()
  local plugins = {
    ['fzf.vim'] = 'https://raw.githubusercontent.com/junegunn/fzf/HEAD/plugin/fzf.vim';
  }
  for file_name, url in pairs(plugins) do
    execute([[curl --create-dirs -sLo %s/autoload/%s %s]], site_dir, file_name, url)
  end
end

do
  local ops = {
    autoload = install_autoload_plugins;
    langservers = setup_langservers;
    virtualenv = ensure_virtualenv;
  }
  local done = {}

  local function sched(name, fn)
    vim.schedule(function()
      fn()
      done[name] = true
    end)
  end

  vfn.mkdir(cache_dir, 'p')
  for name, fn in pairs(ops) do
    sched(name, fn)
  end

  local timeout_min = 30
  local status = vim.wait(timeout_min * minute_ms, function()
    for name in pairs(ops) do
      if not done[name] then
        return false
      end
    end
    return true
  end, 25)
  if not status then
    local parts = {string.format('timed out after %d minutes', timeout_min)}
    for k, _ in pairs(ops) do
      table.insert(parts, string.format('%s = %s', k, done[k] or false))
    end
    error(table.concat(parts, '\n'))
  end
end
