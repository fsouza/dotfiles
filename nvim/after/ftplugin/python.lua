local function is_python_test(fname)
  return (string.find(fname, "test_.*%.py$") ~= nil) or
         (string.find(fname, ".*_test%.py$") ~= nil)
end

local function start_pyright(bufnr, python_interpreter)
  local servers = require("fsouza.lsp.servers")
  python_interpreter = python_interpreter or
                      vim.fs.joinpath(_G.cache_dir, "venv", "bin", "python3")
  
  servers.start({
    bufnr = bufnr,
    config = {
      name = "pyright",
      cmd = {"pyright-langserver", "--stdio"},
      cmd_env = {NODE_OPTIONS = "--max-old-space-size=16384"},
      settings = {
        pyright = {},
        python = {
          pythonPath = python_interpreter,
          analysis = {
            autoImportCompletions = true,
            autoSearchPaths = true,
            diagnosticMode = vim.g.pyright_diagnostic_mode or "workspace",
            typeCheckingMode = vim.g.pyright_type_checking_mode or "basic",
            useLibraryCodeForTypes = true
          }
        }
      }
    },
    opts = {
      ["diagnostic-filter"] = function()
        local pyright = require("fsouza.lsp.servers.pyright")
        return pyright.valid_diagnostic
      end
    },
    cb = function()
      local references = require("fsouza.lsp.references")
      references.register_test_checker(".py", "python", is_python_test)
    end
  })
end

local function start_ruff_server(bufnr, root_dir)
  local lsp_servers = require("fsouza.lsp.servers")
  lsp_servers.start({
    bufnr = bufnr,
    config = {
      name = "ruff-server",
      cmd = {
        vim.fs.joinpath(_G.cache_dir, "venv", "bin", "ruff"),
        "server"
      },
      init_options = {settings = {lint = {enable = true}}}
    },
    find_root_dir = function() return root_dir end,
    opts = {autofmt = 2, auto_action = "source.fixAll.ruff"}
  })
end

local function maybe_start_ruff_server(bufnr)
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  -- TODO: support pyproject.toml
  local ruff_config = vim.fs.find(
    {"ruff.toml", ".ruff.toml"},
    {upward = true, type = "file", path = vim.fs.dirname(bufname)}
  )
  local ruff_config = ruff_config[1]
  
  if ruff_config then
    start_ruff_server(bufnr, vim.fs.dirname(ruff_config))
  end
end

local function get_python_tools(cb)
  local gen_python_tools = vim.fs.joinpath(
    _G.dotfiles_cache_dir, "bin", "gen-efm-python-tools"
  )
  
  local function on_finished(result)
    if result.code ~= 0 then
      error(result.stderr)
    else
      cb(vim.json.decode(result.stdout))
    end
  end
  
  vim.system(
    {gen_python_tools, "-venv", vim.fs.joinpath(_G.cache_dir, "venv")},
    nil,
    vim.schedule_wrap(on_finished)
  )
end

local bufnr = vim.api.nvim_get_current_buf()
local efm = require("fsouza.lsp.servers.efm")
local detect_interpreter = require("fsouza.lib.python").detect_interpreter

get_python_tools(function(tools)
  vim.schedule(function() efm.add(bufnr, "python", tools) end)
end)

detect_interpreter(function(interpreter)
  vim.schedule(function() start_pyright(bufnr, interpreter) end)
end)

maybe_start_ruff_server(bufnr)