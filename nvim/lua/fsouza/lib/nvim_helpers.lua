local M = {fns = {}}

local api = vim.api
local vcmd = vim.cmd
local vfn = vim.fn

local function register_cb(fn)
  local id = tostring(fn)
  M.fns[id] = fn
  return id
end

function M.cmd_map(cmd)
  return string.format('<cmd>%s<cr>', cmd)
end

function M.vcmd_map(cmd)
  return string.format([[<cmd>'<,'>%s<cr>]], cmd)
end

function M.fn_cmd(fn)
  local id = register_cb(fn)
  return string.format([[lua require('fsouza.lib.nvim_helpers').fns['%s']()]], id)
end

function M.fn_map(fn)
  return M.cmd_map(M.fn_cmd(fn))
end

function M.vfn_map(fn)
  return M.vcmd_map(M.fn_cmd(fn))
end

function M.ifn_map(fn)
  local id = register_cb(fn)
  return string.format([[<c-r>=luaeval("require('fsouza.lib.nvim_helpers').fns['%s']()")<CR>]], id)
end

function M.create_mappings(mappings, bufnr)
  local fn = api.nvim_set_keymap
  if bufnr then
    fn = function(...)
      api.nvim_buf_set_keymap(bufnr, ...)
    end
  end

  for mode, rules in pairs(mappings) do
    for _, m in ipairs(rules) do
      fn(mode, m.lhs, m.rhs, m.opts or {})
    end
  end
end

function M.remove_mappings(mappings, bufnr)
  local fn = api.nvim_del_keymap
  if bufnr then
    fn = function(...)
      api.nvim_buf_del_keymap(bufnr, ...)
    end
  end

  for mode, rules in pairs(mappings) do
    for _, m in ipairs(rules) do
      fn(mode, m.lhs)
    end
  end
end

function M.exec_cmds(cmd_list)
  vcmd(table.concat(cmd_list, '\n'))
end

function M.augroup(name, commands)
  vcmd('augroup ' .. name)
  vcmd('autocmd!')
  for _, c in ipairs(commands) do
    vcmd(string.format('autocmd %s %s %s %s', table.concat(c.events, ','),
                       table.concat(c.targets or {}, ','), table.concat(c.modifiers or {}, ' '),
                       c.command))
  end
  vcmd('augroup END')
end

function M.reset_augroup(name)
  M.augroup(name, {})
end

function M.ensure_path_relative_to_prefix(prefix, path)
  if not vim.endswith(prefix, '/') then
    prefix = prefix .. '/'
  end
  if vim.startswith(path, prefix) then
    return string.sub(path, string.len(prefix) + 1)
  end
  return path
end

function M.rewrite_wrap(bufnr, fn)
  local winid = api.nvim_get_current_win()
  local win_bufnr = api.nvim_win_get_buf(winid)

  local restore = function()
  end
  if bufnr == win_bufnr then
    local cursor = api.nvim_win_get_cursor(winid)
    local orig_lineno, orig_colno = cursor[1], cursor[2]
    local orig_line = api.nvim_buf_get_lines(bufnr, orig_lineno - 1, orig_lineno, true)[1]
    local orig_nlines = api.nvim_buf_line_count(bufnr)
    local view = vfn.winsaveview()

    -- note: this isn't 100% correct, if the lines change below the current one,
    -- the position won't be the same, but this is optmistic: if the file was
    -- already formatted before, the lines below will mostly do the right thing.
    restore = function()
      local line_offset = api.nvim_buf_line_count(bufnr) - orig_nlines
      local lineno = orig_lineno + line_offset
      local col_offset = string.len(api.nvim_buf_get_lines(bufnr, lineno - 1, lineno, true)[1] or
                                      '') - string.len(orig_line)
      view.lnum = lineno
      view.col = orig_colno + col_offset
      vfn.winrestview(view)
    end
  end

  fn()

  restore()
end

return M
