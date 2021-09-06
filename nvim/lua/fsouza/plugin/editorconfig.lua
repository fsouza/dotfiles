local vfn = vim.fn
local vcmd = vim.cmd
local api = vim.api
local nvim_buf_get_option = api.nvim_buf_get_option
local nvim_buf_set_option = api.nvim_buf_set_option
local helpers = require('fsouza.lib.nvim_helpers')

local M = {}

local function parse_output(data)
  local lines = vim.split(data, '\n')
  local opts = {}
  require('fsouza.tablex').foreach(lines, function(line)
    local parts = vim.split(line, '=')
    if #parts == 2 then
      opts[parts[1]] = parts[2]
    end
  end)
  return opts
end

local function get_vim_fenc(editorconfig_charset)
  if editorconfig_charset == 'utf-8' or editorconfig_charset == 'latin1' then
    return editorconfig_charset, false
  elseif editorconfig_charset == 'utf-16be' or editorconfig_charset == 'utf-16le' then
    return editorconfig_charset, true
  else
    return 'utf-8', true
  end
end

local function get_vim_fileformat(editorconfig_eol)
  local m = {crlf = 'dos'; cr = 'mac'}
  return m[editorconfig_eol] or 'unix'
end

local function trim_whitespace()
  local view = vfn.winsaveview()
  pcall(function()
    vcmd([[silent! keeppatterns %s/\v\s+$//]])
  end)
  vfn.winrestview(view)
end

local function handle_whitespaces(bufnr, v)
  local commands = {}
  if v == 'true' then
    table.insert(commands, {
      events = {'BufWritePre'};
      targets = {string.format('<buffer=%d>', bufnr)};
      command = helpers.fn_cmd(trim_whitespace);
    })
  end

  if api.nvim_buf_is_valid(bufnr) then
    helpers.augroup('editorconfig_trim_trailing_whitespace_' .. bufnr, commands)
  end
end

local function set_opts(bufnr, opts)
  local vim_opts = {tabstop = 8}
  require('fsouza.tablex').foreach(opts, function(v, k)
    if k == 'charset' then
      vim_opts.fileencoding, vim_opts.bomb = get_vim_fenc(v)
    end

    if k == 'end_of_line' then
      vim_opts.fileformat = get_vim_fileformat(v)
    end

    if k == 'indent_style' then
      vim_opts.expandtab = v == 'spaces' or v == 'space'
    end

    if k == 'insert_final_line' or k == 'insert_final_newline' then
      vim_opts.fixendofline = v == 'true'
    end

    if k == 'indent_size' then
      local indent_size = tonumber(v)
      vim_opts.shiftwidth = indent_size
      vim_opts.softtabstop = indent_size
    end

    if k == 'trim_trailing_whitespace' then
      vim.schedule(function()
        handle_whitespaces(bufnr, v)
      end)
    end
  end)

  vim.schedule(function()
    if api.nvim_buf_is_valid(bufnr) and nvim_buf_get_option(bufnr, 'modifiable') then
      require('fsouza.tablex').foreach(vim_opts, function(value, option_name)
        nvim_buf_set_option(bufnr, option_name, value)
      end)
    end
  end)
end

local function set_config(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  if not vim.bo[bufnr].modifiable or vim.bo[bufnr].readonly then
    return
  end
  local filename = api.nvim_buf_get_name(bufnr)
  if filename == '' then
    return
  end

  -- assume it's a relative path
  if not vim.startswith(filename, '/') then
    filename = require('pl.path').join(vfn.getcwd(), filename)
  end

  require('fsouza.lib.cmd').run('editorconfig', {args = {filename}}, nil, function(result)
    if result.exit_status ~= 0 then
      print(string.format('failed to run editorconfig: %d - %s', result.exit_status, result.stderr))
      return
    end

    local opts = parse_output(result.stdout)
    set_opts(bufnr, opts)
  end)
end

local set_config_cmd = helpers.fn_cmd(set_config)

local function set_enabled(v)
  local commands = {}
  if v then
    table.insert(commands, {
      events = {'BufNewFile'; 'BufReadPost'; 'BufFilePost'};
      targets = {'*'};
      command = set_config_cmd;
    });
    vim.schedule(function()
      require('fsouza.tablex').foreach(api.nvim_list_bufs(), set_config)
    end)
  end
  helpers.augroup('editorconfig', commands)
end

function M.enable()
  set_enabled(true)
end

function M.disable()
  set_enabled(false)
end

return M
