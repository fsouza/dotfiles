local M = {}

local vfn = vim.fn
local loop = vim.loop

local default_root_markers = {'.git'}
local config_dir = vfn.stdpath('config')
local cache_dir = vfn.stdpath('cache')

local function quote_arg(arg)
  return string.format('"%s"', arg)
end

local function process_args(args)
  return table.concat(vim.tbl_map(quote_arg, args or {}), ' ')
end

local function get_node_bin(bin_name)
  local local_bin = string.format([[node_modules/.bin/%s]], bin_name)
  if vfn.executable(local_bin) == 1 then
    return local_bin
  end
  return string.format([[%s/langservers/node_modules/.bin/%s]], config_dir, bin_name)
end

local function get_python_bin(bin_name)
  if vim.env.VIRTUAL_ENV then
    local venv_bin_name = string.format('%s/bin/%s', vim.env.VIRTUAL_ENV, bin_name)
    if vfn.executable(venv_bin_name) == 1 then
      return venv_bin_name
    end
  end
  return string.format('%s/venv/bin/%s', cache_dir, bin_name)
end

local function get_black(args)
  return {
    formatCommand = string.format('%s --fast --quiet %s -', get_python_bin('black'),
                                  process_args(args));
    formatStdin = true;
    rootMarkers = {'.git'; ''};
  }
end

local function get_isort(args)
  return {
    formatCommand = string.format('%s %s -', get_python_bin('isort'), process_args(args));
    formatStdin = true;
    rootMarkers = {'.isort.cfg'; '.git'; ''};
  }
end

local function get_autoflake()
  return {
    formatCommand = string.format('%s --stdin-display-name ${INPUT} --remove-all-unused-imports -',
                                  get_python_bin('autoflake'));
    formatStdin = true;
    rootMarkers = default_root_markers;
  }
end

local function get_flake8(args)
  return {
    lintCommand = string.format(
      '%s --stdin-display-name ${INPUT} --format "%%(path)s:%%(row)d:%%(col)d: %%(code)s %%(text)s" %s -',
      get_python_bin('flake8'), process_args(args));
    lintStdin = true;
    lintSource = 'flake8';
    lintFormats = {'%f:%l:%c: %m'};
    rootMarkers = {'.flake8'; '.git'; ''};
  }, get_autoflake
end

local function get_add_trailing_comma(args)
  return {
    formatCommand = string.format('%s --exit-zero-even-if-changed %s -',
                                  get_python_bin('add-trailing-comma'), process_args(args));
    formatStdin = true;
    rootMarkers = default_root_markers;
  }
end

local function get_reorder_python_imports(args)
  return {
    formatCommand = string.format('%s --exit-zero-even-if-changed %s -',
                                  get_python_bin('reorder-python-imports'), process_args(args));
    formatStdin = true;
    rootMarkers = default_root_markers;
  }
end

local function get_autopep8(args)
  return {
    formatCommand = string.format('%s %s -', get_python_bin('autopep8'), process_args(args));
    formatStdin = true;
    rootMarkers = default_root_markers;
  }
end

local function get_buildifier()
  local nvim_config_path = config_dir
  local bin = nvim_config_path .. '/langservers/bin/buildifierw'
  if vfn.executable('buildifier') == 1 then
    return {
      formatCommand = string.format('%s ${INPUT}', bin);
      formatStdin = true;
      rootMarkers = default_root_markers;
    }
  end
  return {}
end

local function get_dune()
  return {
    formatCommand = 'dune format-dune-file';
    formatStdin = true;
    rootMarkers = default_root_markers;
  }
end

local function get_shellcheck()
  return {
    lintCommand = 'shellcheck -f gcc -x -';
    lintStdin = true;
    lintSource = 'shellcheck';
    lintFormats = {'%f:%l:%c: %trror: %m'; '%f:%l:%c: %tarning: %m'; '%f:%l:%c: %tote: %m'};
    rootMarkers = default_root_markers;
  }
end

local function get_shfmt()
  return {
    formatCommand = string.format('%s/langservers/bin/shfmt -', cache_dir);
    formatStdin = true;
    rootMarkers = default_root_markers;
  }
end

local function get_luacheck()
  return {
    lintCommand = string.format('%s/hr/bin/luacheck --formatter plain --filename ${INPUT} -',
                                cache_dir);
    lintStdin = true;
    lintSource = 'luacheck';
    rootMarkers = default_root_markers;
    lintFormats = {'%f:%l:%c: %m'};
  }
end

local function get_luaformat()
  return {
    formatCommand = string.format('%s/hr/bin/lua-format', cache_dir);
    formatStdin = true;
    rootMarkers = {'.lua-format'; '.git'};
  }
end

local function get_prettierd()
  return {
    formatCommand = string.format('%s ${INPUT}', get_node_bin('prettierd'));
    formatStdin = true;
    env = {'XDG_RUNTIME_DIR=' .. cache_dir};
  }
end

local function get_eslintd_config()
  local eslint_config_files = {
    '.eslintrc.js';
    '.eslintrc.cjs';
    '.eslintrc.yaml';
    '.eslintrc.yml';
    '.eslintrc.json';
  }
  for _, config_file in ipairs(eslint_config_files) do
    if loop.fs_stat(config_file) then
      return {
        {
          formatCommand = string.format('%s --stdin --stdin-filename ${INPUT} --fix-to-stdout',
                                        get_node_bin('eslint_d'));
          formatStdin = true;
          env = {'XDG_RUNTIME_DIR=' .. cache_dir};
        };
        {
          lintCommand = string.format('%s --stdin --stdin-filename ${INPUT} --format unix',
                                      get_node_bin('eslint_d'));
          lintStdin = true;
          lintSource = 'eslint';
          rootMarkers = {
            '.eslintrc.js';
            '.eslintrc.cjs';
            '.eslintrc.yaml';
            '.eslintrc.yml';
            '.eslintrc.json';
            '.git';
            'package.json';
          };
          lintFormats = {'%f:%l:%c: %m'};
          env = {'XDG_RUNTIME_DIR=' .. cache_dir};
        };
      }
    end
  end
  return {}
end

local function read_precommit_config(file_path)
  local lyaml = prequire('lyaml')
  if not lyaml then
    return {repos = {}}
  end
  local f = io.open(file_path, 'r')
  local content = f:read('all*')
  f:close()
  return lyaml.load(content)
end

local function get_python_tools()
  local pre_commit_config_file_path = '.pre-commit-config.yaml'
  if not loop.fs_stat(pre_commit_config_file_path) then
    return {
      get_flake8();
      get_black();
      get_add_trailing_comma();
      get_reorder_python_imports();
      get_autoflake();
    }
  end

  local pc_repo_tools = {
    ['https://gitlab.com/pycqa/flake8'] = get_flake8;
    ['https://github.com/pycqa/flake8'] = get_flake8;
    ['https://github.com/psf/black'] = get_black;
    ['https://github.com/asottile/add-trailing-comma'] = get_add_trailing_comma;
    ['https://github.com/asottile/reorder_python_imports'] = get_reorder_python_imports;
    ['https://github.com/pre-commit/mirrors-autopep8'] = get_autopep8;
    ['https://github.com/pre-commit/mirrors-isort'] = get_isort;
    ['https://github.com/myint/autoflake'] = get_autoflake;
  }
  local local_repos_mapping = {['black'] = 'https://github.com/psf/black'}
  local pre_commit_config = read_precommit_config(pre_commit_config_file_path)
  local tools = {}
  for _, repo in ipairs(pre_commit_config.repos) do
    local repo_url = repo.repo
    if repo.repo == 'local' then
      if repo.hooks[1] then
        repo_url = local_repos_mapping[repo.hooks[1].id]
      end
    end
    local args = {}
    if repo.hooks[1] and vim.tbl_islist(repo.hooks[1].args) then
      args = repo.hooks[1].args
    end
    local fn = pc_repo_tools[repo_url]
    while fn do
      local r
      r, fn = fn(args)
      table.insert(tools, r)
    end
  end

  return tools
end

local function get_lua_tools()
  local tools = {}
  if loop.fs_stat('.luacheckrc') then
    table.insert(tools, get_luacheck())
  end
  if loop.fs_stat('.lua-format') then
    table.insert(tools, get_luaformat())
  end
  return tools
end

local function get_settings()
  local settings = {lintDebounce = 250000000; rootMarkers = default_root_markers; languages = {}}
  local function add_if_not_empty(language, tool)
    if tool.formatCommand or tool.lintCommand then
      local tools = settings.languages[language] or {}
      table.insert(tools, tool)
      settings.languages[language] = tools
    end
  end

  local tools_mapping = {python = get_python_tools; lua = get_lua_tools}
  for language, tools_fn in pairs(tools_mapping) do
    local tools = tools_fn()
    if #tools > 0 then
      settings.languages[language] = tools
    end
  end
  add_if_not_empty('sh', get_shellcheck())
  add_if_not_empty('sh', get_shfmt())
  add_if_not_empty('dune', get_dune())
  add_if_not_empty('bzl', get_buildifier())

  local eslint_tools = get_eslintd_config()
  local eslint_fts = {'javascript'; 'typescript'}
  for _, eslint in ipairs(eslint_tools) do
    for _, ft in ipairs(eslint_fts) do
      add_if_not_empty(ft, eslint)
    end
  end

  local prettierd = get_prettierd()
  local prettierd_fts = {
    'css';
    'graphql';
    'html';
    'javascript';
    'json';
    'typescript';
    'typescriptreact';
    'yaml';
  }
  for _, ft in ipairs(prettierd_fts) do
    add_if_not_empty(ft, prettierd)
  end

  return settings
end

function M.gen_config()
  local settings = get_settings()
  return settings, vim.tbl_keys(settings.languages)
end

return M
