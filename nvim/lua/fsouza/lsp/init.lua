local path = require('pl.path')

local vfn = vim.fn

local config_dir = vfn.stdpath('config')
local cache_dir = vfn.stdpath('cache')

local function get_local_cmd(cmd)
  return path.join(config_dir, 'langservers', 'bin', cmd)
end

local function get_cache_cmd(cmd)
  return path.join(cache_dir, 'langservers', 'bin', cmd)
end

local function set_log_level()
  local level = 'ERROR'
  if vim.env.NVIM_DEBUG then
    level = 'TRACE'
  end
  require('vim.lsp.log').set_level(level)
end

local function define_signs()
  local levels = {'Error'; 'Warning'; 'Information'; 'Hint'}
  require('fsouza.tablex').foreach(levels, function(level)
    local sign_name = 'LspDiagnosticsSign' .. level
    vfn.sign_define(sign_name, {text = ''; texthl = sign_name; numhl = sign_name})
  end)
end

-- override some stuff in vim.lsp
local function patch_lsp()
  -- disable unsupported method so I don't get random errors.
  vim.lsp._unsupported_methood = function()
  end

  -- override show_line_diagnostics and show_position_diagnostics so I can get
  -- the proper theme in the popup window.
  local original_show_line_diagnostics = vim.lsp.diagnostic.show_line_diagnostics
  vim.lsp.diagnostic.show_line_diagnostics = function(...)
    local bufnr, winid = original_show_line_diagnostics(...)
    require('fsouza.color').set_popup_winid(winid)
    return bufnr, winid
  end

  local original_show_position_diagnostics = vim.lsp.diagnostic.show_line_diagnostics
  vim.lsp.diagnostic.show_position_diagnostics = function(...)
    local bufnr, winid = original_show_position_diagnostics(...)
    require('fsouza.color').set_popup_winid(winid)
    return bufnr, winid
  end
end

do
  patch_lsp()
  define_signs()

  local function if_executable(name, cb)
    if vfn.executable(name) == 1 then
      cb()
    end
  end

  set_log_level()
  local lsp = require('lspconfig')
  local opts = require('fsouza.lsp.opts')

  if_executable('fnm', function()
    local nvim_python = path.join(cache_dir, 'venv', 'bin', 'python3')
    local nvim_node_ls = get_local_cmd('node-lsp.py')
    lsp.bashls.setup(opts.with_defaults({
      cmd = {nvim_python; nvim_node_ls; 'bash-language-server'; 'start'};
    }))

    lsp.cssls.setup(opts.with_defaults({
      cmd = {nvim_python; nvim_node_ls; 'vscode-css-language-server'; '--stdio'};
    }))

    lsp.html.setup(opts.with_defaults({
      cmd = {nvim_python; nvim_node_ls; 'vscode-html-language-server'; '--stdio'};
    }))

    lsp.jsonls.setup(opts.with_defaults({
      cmd = {nvim_python; nvim_node_ls; 'vscode-json-language-server'; '--stdio'};
    }))

    lsp.tsserver.setup(opts.with_defaults({
      cmd = {nvim_python; nvim_node_ls; 'typescript-language-server'; '--stdio'};
    }))

    lsp.yamlls.setup(opts.with_defaults({
      cmd = {nvim_python; nvim_node_ls; 'yaml-language-server'; '--stdio'};
    }))

    lsp.pyright.setup(opts.with_defaults({
      cmd = {nvim_python; nvim_node_ls; 'pyright-langserver'; '--stdio'};
      settings = {
        pyright = {};
        python = {
          pythonPath = '/usr/bin/python3';
          analysis = {
            autoImportCompletions = true;
            autoSearchPaths = true;
            diagnosticMode = 'workspace';
            typeCheckingMode = vim.g.pyright_type_checking_mode or 'basic';
            useLibraryCodeForTypes = true;
          };
        };
      };
      on_init = function(client)
        require('fsouza.lsp.pyright').detect_pythonPath(client)
        return true
      end;
    }))
  end)

  if_executable('go', function()
    lsp.gopls.setup(opts.with_defaults({
      cmd = {get_cache_cmd('gopls')};
      root_dir = opts.root_pattern_with_fallback('go.mod');
      init_options = {
        deepCompletion = false;
        staticcheck = true;
        analyses = {
          fillreturns = true;
          nonewvars = true;
          undeclaredname = true;
          unusedparams = true;
          ST1000 = false;
        };
        linksInHover = false;
        codelenses = {vendor = false};
        gofumpt = true;
      };
    }))

    local settings, filetypes = require('fsouza.lsp.efm').basic_settings()
    lsp.efm.setup(opts.with_defaults({
      cmd = {get_cache_cmd('efm-langserver')};
      init_options = {documentFormatting = true};
      settings = settings;
      filetypes = filetypes;
      on_init = function(client)
        require('fsouza.lsp.efm').gen_config(client)
        return true
      end;
    }))
  end)

  if_executable('dune', function()
    lsp.ocamllsp.setup(opts.with_defaults({
      cmd = {
        path.join(cache_dir, 'langservers', 'ocaml-lsp', '_build', 'install', 'default', 'bin',
                  'ocamllsp');
      };
      root_dir = opts.root_pattern_with_fallback('.merlin', 'package.json');
    }))
  end)

  if_executable('dotnet', function()
    lsp.fsautocomplete.setup(opts.with_defaults({
      root_dir = opts.root_pattern_with_fallback('*.fsproj', '*.sln');
    }))
  end)

  if_executable('sourcekit-lsp', function()
    lsp.sourcekit.setup(opts.with_defaults({}))
  end)
end
