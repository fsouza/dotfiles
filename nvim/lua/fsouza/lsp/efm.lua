local path = require("pl.path")

local loop = vim.loop
local vfn = vim.fn

local default_root_markers = {".git"}
local config_dir = vfn.stdpath("config")
local cache_dir = vfn.stdpath("cache")

local M = {}

local function quote_arg(arg)
  return string.format("\"%s\"", arg)
end

local function process_args(args)
  return require("fsouza.tablex").reduce(function(acc, arg)
    return acc .. quote_arg(arg)
  end, args or {}, "")
end

local function find_venv_bin(bin_name)
  return path.join(cache_dir, "venv", "bin", bin_name)
end

local function if_bin(bin_to_check, fallback_bin, cb)
  loop.fs_stat(bin_to_check, function(err, stat)
    if err == nil and stat.type == "file" then
      cb(bin_to_check)
    else
      cb(fallback_bin)
    end
  end)
end

local function get_node_bin(bin_name, cb)
  local local_bin = path.join("node_modules", ".bin", bin_name)
  local default_bin = path.join(config_dir, "langservers", "node_modules", ".bin", bin_name)
  if_bin(local_bin, default_bin, cb)
end

local function get_python_bin(bin_name, cb)
  local virtualenv = os.getenv("VIRTUAL_ENV")
  local default_bin = find_venv_bin(bin_name)
  if virtualenv then
    local venv_bin_name = path.join(virtualenv, "bin", bin_name)
    if_bin(venv_bin_name, default_bin, cb)
  else
    cb(default_bin)
  end
end

local function get_black(args, cb)
  get_python_bin("black", function(black_path)
    cb({
      formatCommand = string.format("%s --fast --quiet %s -", black_path, process_args(args));
      formatStdin = true;
      rootMarkers = {".git"; ""};
    })
  end)
end

local function get_isort(args, cb)
  get_python_bin("isort", function(isort_path)
    cb({
      formatCommand = string.format("%s %s -", isort_path, process_args(args));
      formatStdin = true;
      rootMarkers = {".isort.cfg"; ".git"; ""};
    })
  end)
end

local function get_autoflake8(_, cb)
  get_python_bin("autoflake8", function(autoflake8_path)
    cb({
      formatCommand = string.format("%s --expand-star-imports --exit-zero-even-if-changed -",
                                    autoflake8_path);
      formatStdin = true;
      rootMarkers = default_root_markers;
    })
  end)
end

local function get_flake8(args, cb)
  get_python_bin("flake8", function(flake8_path)
    cb({
      lintCommand = string.format(
        "%s --stdin-display-name ${INPUT} --format \"%%(path)s:%%(row)d:%%(col)d: %%(code)s %%(text)s\" %s -",
        flake8_path, process_args(args));
      lintStdin = true;
      lintSource = "flake8";
      lintFormats = {"%f:%l:%c: %m"};
      rootMarkers = {".flake8"; ".git"; ""};
    }, get_autoflake8)
  end)
end

local function get_add_trailing_comma(args, cb)
  get_python_bin("add-trailing-comma", function(atc_path)
    cb({
      formatCommand = string.format("%s --exit-zero-even-if-changed %s -", atc_path,
                                    process_args(args));
      formatStdin = true;
      rootMarkers = default_root_markers;
    })
  end)
end

local function get_reorder_python_imports(args, cb)
  get_python_bin("reorder-python-imports", function(rpi_path)
    cb({
      formatCommand = string.format("%s --exit-zero-even-if-changed %s -", rpi_path,
                                    process_args(args));
      formatStdin = true;
      rootMarkers = default_root_markers;
    })
  end)
end

local function get_autopep8(args, cb)
  get_python_bin("reorder-python-imports", function(rpi_path)
    cb({
      formatCommand = string.format("%s %s -", rpi_path, process_args(args));
      formatStdin = true;
      rootMarkers = default_root_markers;
    })
  end)
end

local function get_buildifier(cb)
  local buildifierw = path.join(config_dir, "langservers", "bin", "buildifierw.py")
  cb({
    formatCommand = string.format("%s %s ${INPUT}", find_venv_bin("python3"), buildifierw);
    formatStdin = true;
    rootMarkers = default_root_markers;
    env = {"NVIM_CACHE_DIR=" .. cache_dir};
  })
end

local function get_dune(cb)
  cb({
    formatCommand = "dune format-dune-file";
    formatStdin = true;
    rootMarkers = default_root_markers;
  })
end

local function get_shellcheck(cb)
  cb({
    lintCommand = "shellcheck -f gcc -x -";
    lintStdin = true;
    lintSource = "shellcheck";
    lintFormats = {"%f:%l:%c: %trror: %m"; "%f:%l:%c: %tarning: %m"; "%f:%l:%c: %tote: %m"};
    rootMarkers = default_root_markers;
  })
end

local function get_shfmt(cb)
  cb({
    formatCommand = string.format("%s -", path.join(cache_dir, "langservers", "bin", "shfmt"));
    formatStdin = true;
    rootMarkers = default_root_markers;
  })
end

local function get_luacheck(cb)
  local tool = {}
  loop.fs_stat(".luacheckrc", function(err, stat)
    if err == nil and stat.type == "file" then
      tool = {
        lintCommand = string.format(
          "%s/hr/bin/luacheck --formatter plain --no-default-config --filename ${INPUT} -",
          cache_dir);
        lintStdin = true;
        lintSource = "luacheck";
        rootMarkers = default_root_markers;
        lintFormats = {"%f:%l:%c: %m"};
      }
    end
    cb(tool)
  end)
end

local function get_luaformat(cb)
  local tool = {}
  loop.fs_stat(".lua-format", function(err, stat)
    if err == nil and stat.type == "file" then
      tool = {
        formatCommand = path.join(cache_dir, "hr", "bin", "lua-format");
        formatStdin = true;
        rootMarkers = {".lua-format"; ".git"};
      }
    end
    cb(tool)
  end)
end

local function get_prettierd(cb)
  get_node_bin("prettierd", function(prettierd_path)
    cb({
      formatCommand = string.format("%s ${INPUT}", prettierd_path);
      formatStdin = true;
      env = {"XDG_RUNTIME_DIR=" .. cache_dir};
    })
  end)
end

local function get_eslintd_config(cb)
  get_node_bin("eslint_d", function(eslint_d_path)
    local eslint_config_files = {
      ".eslintrc.js";
      ".eslintrc.cjs";
      ".eslintrc.yaml";
      ".eslintrc.yml";
      ".eslintrc.json";
    }

    local function check_eslint_d_config(idx)
      local config_file = eslint_config_files[idx]
      if not config_file then
        cb({})
        return
      end

      loop.fs_stat(config_file, function(err, stat)
        if err ~= nil or stat.type ~= "file" then
          return check_eslint_d_config(idx + 1)
        end

        cb({
          {
            formatCommand = string.format("%s --stdin --stdin-filename ${INPUT} --fix-to-stdout",
                                          eslint_d_path);
            formatStdin = true;
            env = {"XDG_RUNTIME_DIR=" .. cache_dir};
          };
          {
            lintCommand = string.format("%s --stdin --stdin-filename ${INPUT} --format unix",
                                        eslint_d_path);
            lintStdin = true;
            lintSource = "eslint";
            rootMarkers = {
              ".eslintrc.js";
              ".eslintrc.cjs";
              ".eslintrc.yaml";
              ".eslintrc.yml";
              ".eslintrc.json";
              ".git";
              "package.json";
            };
            lintFormats = {"%f:%l:%c: %m"};
            env = {"XDG_RUNTIME_DIR=" .. cache_dir};
          };
        })
      end)
    end

    check_eslint_d_config(1)
  end)
end

local function try_read_precommit_config(file_path, cb)
  local empty_result = {repos = {}}

  local lyaml = prequire("lyaml")
  if not lyaml then
    cb(empty_result)
    return
  end

  loop.fs_open(file_path, "r", tonumber("644", 8), function(err, fd)
    if err then
      cb(empty_result)
      return
    end

    local offset = 0
    local block_size = 1024
    local content = ""

    local function on_read(read_err, chunk)
      if read_err then
        cb(empty_result)
        return
      end

      if #chunk == 0 then
        loop.fs_close(fd)
        cb(lyaml.load(content))
        return
      end

      content = content .. chunk

      offset = offset + block_size
      loop.fs_read(fd, block_size, offset, on_read)
    end

    loop.fs_read(fd, block_size, offset, on_read)
  end)
end

local function get_python_tools(cb)
  local fns = {
    {fn = get_flake8};
    {fn = get_black};
    {fn = get_add_trailing_comma};
    {fn = get_reorder_python_imports};
    {fn = get_autoflake8};
  }
  local pre_commit_config_file_path = ".pre-commit-config.yaml"

  try_read_precommit_config(pre_commit_config_file_path, function(pre_commit_config)
    local pc_repo_tools = {
      ["https://gitlab.com/pycqa/flake8"] = get_flake8;
      ["https://github.com/pycqa/flake8"] = get_flake8;
      ["https://github.com/psf/black"] = get_black;
      ["https://github.com/ambv/black"] = get_black;
      ["https://github.com/asottile/add-trailing-comma"] = get_add_trailing_comma;
      ["https://github.com/asottile/reorder_python_imports"] = get_reorder_python_imports;
      ["https://github.com/pre-commit/mirrors-autopep8"] = get_autopep8;
      ["https://github.com/pre-commit/mirrors-isort"] = get_isort;
      ["https://github.com/fsouza/autoflake8"] = get_autoflake8;
    }

    local pre_commit_fns = require("fsouza.tablex")["filter-map"](function(repo)
      local repo_url = repo.repo
      local args = {}
      if repo.hooks[1] and vim.tbl_islist(repo.hooks[1].args) then
        args = repo.hooks[1].args
      end

      local fn = pc_repo_tools[repo_url]
      if fn then
        return {fn = fn; args = args}
      end

      return nil
    end, pre_commit_config.repos)

    if #pre_commit_fns > 0 then
      fns = pre_commit_fns
    end

    local tools = {}
    local pending = 0

    local function process_result(tool, next_fn)
      table.insert(tools, tool)
      if next_fn then
        -- don't propagate args on chained tools.
        next_fn(nil, process_result)
      else
        pending = pending - 1
      end
    end

    require("fsouza.tablex").foreach(fns, function(fn)
      pending = pending + 1
      fn.fn(fn.args, process_result)
    end)

    local timer = vim.loop.new_timer()
    timer:start(0, 25, function()
      if pending == 0 then
        vim.schedule(function()
          cb(tools)
        end)
        timer:close()
      end
    end)
  end)
end

local prettierd_fts = {
  "changelog";
  "css";
  "graphql";
  "html";
  "javascript";
  "json";
  "typescript";
  "typescriptreact";
  "yaml";
}

local function get_filetypes()
  return vim.tbl_flatten({"bzl"; "dune"; "lua"; "python"; "sh"; prettierd_fts})
end

local function get_settings(cb)
  local settings = M.basic_settings()
  settings.languages = {}

  local function add_if_not_empty(language, tool)
    if tool.formatCommand or tool.lintCommand then
      local tools = settings.languages[language] or {}
      table.insert(tools, tool)
      settings.languages[language] = tools
    end
  end

  -- some tools are loaded asynchronously, others are not, but we assume any
  -- can be by supporting the callback style in all of them.
  local pending = 0

  local function pending_wrapper(fn, original_cb)
    pending = pending + 1
    fn(function(...)
      original_cb(...)
      pending = pending - 1
    end)
  end

  local simple_tool_factories = {
    {language = "sh"; fn = get_shellcheck};
    {language = "sh"; fn = get_shfmt};
    {language = "dune"; fn = get_dune};
    {language = "bzl"; fn = get_buildifier};
    {language = "lua"; fn = get_luaformat};
    {language = "lua"; fn = get_luacheck};
  }

  local tablex = require("fsouza.tablex")

  tablex.foreach(simple_tool_factories, function(f)
    pending_wrapper(f.fn, function(tool)
      add_if_not_empty(f.language, tool)
    end)
  end)

  -- prettierd and eslint_d may apply to multiple file types.
  pending_wrapper(get_eslintd_config, function(eslint_tools)
    local eslint_fts = {"javascript"; "typescript"}
    tablex.foreach(eslint_tools, function(eslint)
      tablex.foreach(eslint_fts, function(ft)
        add_if_not_empty(ft, eslint)
      end)
    end)
  end)

  pending_wrapper(get_prettierd, function(prettierd)
    tablex.foreach(prettierd_fts, function(ft)
      add_if_not_empty(ft, prettierd)
    end)
  end)

  -- Python is a whole different kind of fun.
  pending_wrapper(get_python_tools, function(python_tools)
    settings.languages.python = python_tools
  end)

  local timer = vim.loop.new_timer()
  timer:start(0, 25, function()
    if pending == 0 then
      vim.schedule(function()
        cb(settings)
      end)
      timer:close()
    end
  end)
end

function M.basic_settings()
  return {
    lintDebounce = 250000000;
    rootMarkers = default_root_markers;
    languages = vim.empty_dict();
  }, get_filetypes()
end

function M.gen_config(client)
  get_settings(function(settings)
    client.config.settings = settings
    client.notify("workspace/didChangeConfiguration", {settings = client.config.settings})
  end)
end

return M
