local loop = vim.loop

local M = {}

local function set_from_env_var()
  local virtual_env = vim.env.VIRTUAL_ENV
  if virtual_env then
    return virtual_env
  end
  return nil
end

local function set_from_poetry()
  if loop.fs_stat('poetry.lock') then
    local f = io.popen('poetry env info -p 2>/dev/null', 'r')
    if f then
      local virtual_env = f:read()
      f:close()
      return virtual_env
    end
  end
  return nil
end

local function set_from_pipenv()
  if loop.fs_stat('Pipfile.lock') then
    local f = io.popen('pipenv --venv')
    if f then
      local virtual_env = f:read()
      f:close()
      return virtual_env
    end
  end
  return nil
end

local function set_from_venv_folder()
  local folders = {'venv'; '.venv'}
  for _, folder in pairs(folders) do
    local venv_candidate = string.format('%s/%s', loop.cwd(), folder)
    if loop.fs_stat(venv_candidate .. '/bin/python') then
      return venv_candidate
    end
  end
  return nil
end

local function detect_virtual_env(settings)
  local detectors = {set_from_venv_folder; set_from_env_var; set_from_poetry; set_from_pipenv}
  for _, detect in ipairs(detectors) do
    local virtual_env = detect()
    if virtual_env ~= nil then
      vim.env.VIRTUAL_ENV = virtual_env
      settings.python.pythonPath = string.format('%s/bin/python', virtual_env)
      return
    end
  end
end

local function pyright_settings()
  local settings = {
    pyright = {};
    python = {
      analysis = {
        autoImportCompletions = true;
        autoSearchPaths = true;
        diagnosticMode = 'workspace';
        typeCheckingMode = vim.g.pyright_type_checking_mode or 'strict';
        useLibraryCodeForTypes = true;
      };
    };
  }
  detect_virtual_env(settings)
  return settings
end

function M.get_opts(opts)
  opts.settings = pyright_settings()
  return opts
end

return M
