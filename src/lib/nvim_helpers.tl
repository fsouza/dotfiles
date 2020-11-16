local M = {}

local api = vim.api
local nvim_buf_set_keymap = api.nvim_buf_set_keymap
local vcmd = vim.cmd

function M.cmd_map(cmd: string): string
  return string.format('<cmd>%s<cr>', cmd)
end

function M.vcmd_map(cmd: string): string
  return string.format([[<cmd>'<,'>%s<cr>]], cmd)
end

local type Mapping = record
    lhs: string
    rhs: string
    opts: {string:boolean}
end

function M.create_mappings(mappings: {string:{Mapping}}, bufnr: number)
  local fn = api.nvim_set_keymap
  if bufnr then
    fn = function(mode: string, lhs: string, rhs: string, opts: {string:boolean})
      nvim_buf_set_keymap(bufnr, mode, lhs, rhs, opts)
    end
  end

  for mode, rules in pairs(mappings) do
    for _, m in ipairs(rules) do
      fn(mode, m.lhs, m.rhs, m.opts or {})
    end
  end
end

function M.exec_cmds(cmd_list: {string})
  vcmd(table.concat(cmd_list, '\n'))
end

local type Autocmd = record
    events: {string}
    targets: {string}
    command: string
end

function M.augroup(name: string, commands: {Autocmd})
  vcmd('augroup ' .. name)
  vcmd('autocmd!')
  for _, c in ipairs(commands) do
    vcmd(string.format('autocmd %s %s %s', table.concat(c.events, ','),
                       table.concat(c.targets, ','), c.command))
  end
  vcmd('augroup END')
end

function M.ensure_path_relative_to_prefix(prefix: string, path: string): string
  if not vim.endswith(prefix, '/') then
    prefix = prefix .. '/'
  end
  if vim.startswith(path, prefix) then
    return string.sub(path, string.len(prefix) + 1)
  end
  return path
end

function M.rewrite_wrap(fn: function())
  local cursor = api.nvim_win_get_cursor(0)
  local orig_lineno, orig_colno = cursor[1], cursor[2]
  local orig_line = api.nvim_buf_get_lines(0, orig_lineno - 1, orig_lineno, true)[1]
  local orig_nlines = api.nvim_buf_line_count(0)

  fn()

  -- note: this isn't 100% correct, if the lines change below the current one,
  -- the position won't be the same, but this is optmistic: if the file was
  -- already formatted before, the lines below will mostly do the right thing.
  local line_offset = api.nvim_buf_line_count(0) - orig_nlines
  local lineno = orig_lineno + line_offset
  local col_offset = string.len(api.nvim_buf_get_lines(0, lineno - 1, lineno, true)[1]) -
                       string.len(orig_line)
  api.nvim_win_set_cursor(0, {lineno; orig_colno + col_offset})
end

return M
