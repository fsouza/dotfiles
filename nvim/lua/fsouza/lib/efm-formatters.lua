-- this module exists for efm tools that are shared across different file
-- types, such as prettierd and eslintd.

local function get_node_bin(bin_name, cb)
  local local_bin = vim.fs.joinpath("node_modules", ".bin", bin_name)
  local default_bin = string.format(
    "fnm exec --using %s -- %s",
    vim.fs.joinpath(_G.config_dir, "langservers", ".node-version"),
    vim.fs.joinpath(_G.config_dir, "langservers", "node_modules", ".bin", bin_name)
  )

  vim.uv.fs_stat(local_bin, function(err, stat)
    if err == nil and stat.type == "file" then
      cb(local_bin)
    else
      cb(default_bin)
    end
  end)
end

local function with_runtime_dir(tool, cb)
  local xdg_runtime_dir = vim.fs.joinpath(_G.cache_dir, "prettierd")
  local path = require("fsouza.lib.path")
  path.mkdir(xdg_runtime_dir, true, function()
    cb(xdg_runtime_dir)
  end)
end

local function get_prettierd(cb)
  with_runtime_dir("prettierd", function(xdg_runtime_dir)
    local path = require("fsouza.lib.path")
    path.mkdir(xdg_runtime_dir, true, function()
      get_node_bin("prettierd", function(bin_path)
        cb({
          formatCommand = string.format("%s ${INPUT}", bin_path),
          formatStdin = true,
          env = { "XDG_RUNTIME_DIR=" .. xdg_runtime_dir },
        })
      end)
    end)
  end)
end

local function get_eslintd(cb)
  with_runtime_dir("eslintd", function(xdg_runtime_dir)
    get_node_bin("eslint_d", function(bin_path)
      local root_markers = {
        ".eslintrc.js",
        ".eslintrc.cjs",
        ".eslintrc.yaml",
        ".eslintrc.yml",
        ".eslintrc.json",
      }

      cb({
        {
          formatCommand = string.format("%s --stdin --stdin-filename ${INPUT} --fix-to-stdout", bin_path),
          formatStdin = true,
          rootMarkers = root_markers,
          requireMarker = true,
          env = { "XDG_RUNTIME_DIR=" .. xdg_runtime_dir },
        },
        {
          lintCommand = string.format("%s --stdin --stdin-filename ${INPUT} --format unix", bin_path),
          lintStdin = true,
          lintSource = "eslint",
          lintIgnoreExitCode = true,
          lintFormats = { "%f:%l:%c: %m" },
          lintAfterOpen = true,
          rootMarkers = root_markers,
          requireMarker = true,
          env = { "XDG_RUNTIME_DIR=" .. xdg_runtime_dir },
        },
      })
    end)
  end)
end

return {
  get_eslintd = get_eslintd,
  get_prettierd = get_prettierd,
}
