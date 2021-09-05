local vfn = vim.fn

local helpers = require('fsouza.lib.nvim_helpers')

local M = {}

local function set_from_env_var()
  local virtual_env = vim.env.VIRTUAL_ENV
  if virtual_env then
    return virtual_env
  end
  return nil
end

local function set_from_venv_folder()
  local folders = {'venv'; '.venv'}
  for _, folder in pairs(folders) do
    local venv_candidate = string.format('%s/%s', vfn.getcwd(), folder)
    if helpers.filereadable(venv_candidate .. '/bin/python') then
      return venv_candidate
    end
  end
  return nil
end

local function detect_virtual_env(settings)
  local detectors = {set_from_venv_folder; set_from_env_var}
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
        typeCheckingMode = vim.g.pyright_type_checking_mode or 'basic';
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
