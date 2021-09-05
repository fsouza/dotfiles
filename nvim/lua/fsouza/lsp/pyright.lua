local loop = vim.loop
local cmd = require('fsouza.lib.cmd')

local M = {}

local function set_from_env_var(cb)
  cb(os.getenv('VIRTUAL_ENV'))
end

local function set_from_cmd(exec, args, cb)
  cmd.run(exec, {args = args}, nil, function(result)
    if result.exit_status == 0 then
      cb(vim.trim(result.stdout))
    else
      cb(nil)
    end
  end)
end

local function set_from_poetry(cb)
  loop.fs_stat('poetry.lock', function(err, stat)
    if err then
      cb(nil)
      return
    end

    if stat.type == 'file' then
      set_from_cmd('poetry', {'env'; 'info'; '-p'}, cb)
    end
  end)
end

local function set_from_pipenv(cb)
  loop.fs_stat('Pipfile.lock', function(err, stat)
    if err then
      cb(nil)
      return
    end

    if stat.type == 'file' then
      set_from_cmd('pipenv', {'--venv'}, cb)
    end
  end)
end

local function set_from_venv_folder(cb)
  local folders = {'venv'; '.venv'}

  local function test_folder(idx)
    local folder = folders[idx]
    if folder then
      local venv_candidate = string.format('%s/%s', loop.cwd(), folder)
      loop.fs_stat(string.format('%s/bin/python', venv_candidate), function(err, stat)
        if err then
          return test_folder(idx + 1)
        end

        if stat.type == 'file' then
          cb(venv_candidate)
        else
          return test_folder(idx + 1)
        end
      end)
    else
      cb(nil)
    end
  end

  test_folder(1)
end

local function detect_virtualenv(cb)
  local detectors = {set_from_venv_folder; set_from_env_var; set_from_poetry; set_from_pipenv}

  local function detect(idx)
    local detector = detectors[idx]
    if detector then
      detector(function(virtualenv)
        if virtualenv then
          cb(virtualenv)
        else
          detect(idx + 1)
        end
      end)
    end
  end

  detect(1)
end

local function detect_python_interpreter(cb)
  detect_virtualenv(function(virtualenv)
    if virtualenv then
      vim.schedule(function()
        vim.env.VIRTUAL_ENV = virtualenv
      end)
      cb(string.format('%s/bin/python', virtualenv))
    end
  end)
end

function M.detect_pythonPath(client)
  detect_python_interpreter(function(python_path)
    if python_path then
      client.config.settings.python.pythonPath = python_path
      client.notify('workspace/didChangeConfiguration', {settings = client.config.settings})
    end
  end)
end

return M
