local function is_python_test(fname)
  return (string.find(fname, "test_.*%.py$") ~= nil) or (string.find(fname, ".*_test%.py$") ~= nil)
end

local function start_ty(bufnr, python_interpreter)
  local servers = require("fsouza.lsp.servers")
  python_interpreter = python_interpreter or vim.fs.joinpath(_G.cache_dir, "venv", "bin", "python3")

  servers.start({
    bufnr = bufnr,
    config = {
      name = "ty",
      cmd = { "ty", "server" },
      settings = {
        ty = {
          configuration = {
            environment = {
              python = python_interpreter,
            },
          },
        },
      },
    },
    cb = function()
      local references = require("fsouza.lsp.references")
      references.register_test_checker(".py", "python", is_python_test)
    end,
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
        "server",
      },
      init_options = { settings = { lint = { enable = true } } },
    },
    find_root_dir = function()
      return root_dir
    end,
    opts = { autofmt = 2, auto_action = "source.fixAll.ruff" },
  })
end

local function maybe_start_ruff_server(bufnr)
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  -- TODO: support pyproject.toml
  local ruff_config = vim.fs.find(
    { "ruff.toml", ".ruff.toml" },
    { upward = true, type = "file", path = vim.fs.dirname(bufname) }
  )
  local ruff_config = ruff_config[1]

  if ruff_config then
    start_ruff_server(bufnr, vim.fs.dirname(ruff_config))
  end
end

local bufnr = vim.api.nvim_get_current_buf()
local efm = require("fsouza.lsp.servers.efm")
local detect_interpreter = require("fsouza.lib.python").detect_interpreter

detect_interpreter(function(interpreter)
  vim.schedule(function()
    start_ty(bufnr, interpreter)
  end)
end)

maybe_start_ruff_server(bufnr)
