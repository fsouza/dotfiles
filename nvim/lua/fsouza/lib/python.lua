local function set_from_env_var(cb)
  cb(os.getenv("VIRTUAL_ENV") or os.getenv("CONDA_PREFIX"))
end

local function set_from_cmd(cmd, cb)
  vim.system(
    cmd,
    nil,
    vim.schedule_wrap(function(result)
      if result.code == 0 then
        vim.schedule(function()
          cb(vim.trim(result.stdout))
        end)
      else
        vim.schedule(function()
          cb(nil)
        end)
      end
    end)
  )
end

local function set_from_poetry(cb)
  vim.uv.fs_stat("poetry.lock", function(err, stat)
    if not err then
      set_from_cmd({ "poetry", "env", "info", "-p" }, cb)
    else
      cb(nil)
    end
  end)
end

local function set_from_pipenv(cb)
  vim.uv.fs_stat("Pipfile.lock", function(err, stat)
    if not err then
      set_from_cmd({ "pipenv", "--venv" }, cb)
    else
      cb(nil)
    end
  end)
end

local function set_from_venv_folder(cb)
  local folders = { "venv", ".venv" }

  local function test_folder(idx)
    local folder = folders[idx]
    if folder then
      local venv_candidate = vim.fs.joinpath(vim.uv.cwd(), folder)
      local interpreter_candidate = vim.fs.joinpath(venv_candidate, "bin", "python3")

      vim.uv.fs_stat(interpreter_candidate, function(err, stat)
        if not err and stat.type == "file" then
          cb(venv_candidate)
        else
          test_folder(idx + 1)
        end
      end)
    else
      cb(nil)
    end
  end

  test_folder(1)
end

local function detect_virtualenv(cb)
  local detectors = {
    set_from_venv_folder,
    set_from_env_var,
    set_from_poetry,
    set_from_pipenv,
  }

  local function detect(idx)
    local detector = detectors[idx]
    if detector then
      detector(function(result)
        if result then
          cb(result)
        else
          detect(idx + 1)
        end
      end)
    else
      cb(nil)
    end
  end

  detect(1)
end

local function detect_interpreter(cb)
  detect_virtualenv(function(virtualenv)
    if virtualenv then
      vim.schedule(function()
        vim.env.VIRTUAL_ENV = virtualenv
      end)
      cb(vim.fs.joinpath(virtualenv, "bin", "python3"))
    else
      cb(nil)
    end
  end)
end

return {
  detect_interpreter = detect_interpreter,
}
