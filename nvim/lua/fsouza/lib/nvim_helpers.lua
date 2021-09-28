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
  return string.format("<cmd>%s<cr>", cmd)
end

function M.vcmd_map(cmd)
  return string.format("<cmd>'<,'>%s<cr>", cmd)
end

function M.fn_cmd(fn)
  local id = register_cb(fn)
  return string.format("lua require('fsouza.lib.nvim_helpers').fns['%s']()", id)
end

function M.fn_map(fn)
  return M.cmd_map(M.fn_cmd(fn))
end

function M.vfn_map(fn)
  return M.vcmd_map(M.fn_cmd(fn))
end

function M.ifn_map(fn)
  local id = register_cb(fn)
  return string.format("<c-r>=luaeval(\"require('fsouza.lib.nvim_helpers').fns['%s']()\")<CR>", id)
end

function M.create_mappings(mappings, bufnr)
  local fn = api.nvim_set_keymap
  if bufnr then
    fn = require("pl.func").bind1(api.nvim_buf_set_keymap, bufnr)
  end

  local tablex = require("fsouza.tablex")
  tablex.foreach(mappings, function(rules, mode)
    tablex.foreach(rules, function(m)
      fn(mode, m.lhs, m.rhs, m.opts or {})
    end)
  end)
end

function M.remove_mappings(mappings, bufnr)
  local fn = api.nvim_del_keymap
  if bufnr then
    fn = require("pl.func").bind1(api.nvim_buf_del_keymap, bufnr)
  end

  local tablex = require("fsouza.tablex")
  tablex.foreach(mappings, function(rules, mode)
    tablex.foreach(rules, function(m)
      fn(mode, m.lhs)
    end)
  end)
end

function M.augroup(name, commands)
  local tablex = require("fsouza.tablex")

  vcmd("augroup " .. name)
  vcmd("autocmd!")
  tablex.foreach(commands, function(c)
    vcmd(string.format("autocmd %s %s %s %s", table.concat(c.events, ","),
                       table.concat(c.targets or {}, ","), table.concat(c.modifiers or {}, " "),
                       c.command))
  end)
  vcmd("augroup END")
end

function M.reset_augroup(name)
  M.augroup(name, {})
end

--- Provides a wrapper to a function that rewrites the current buffer, and does
--- a best effort to keep the buffer position.
---
--- If you want to run this on a buffer that's not the current one, use
--- nvim_buf_call. See fsouza/lsp/formatting.lua for an example.
function M.rewrite_wrap(fn)
  local bufnr = api.nvim_get_current_buf()

  local cursor = api.nvim_win_get_cursor(0)
  local orig_lineno, orig_colno = cursor[1], cursor[2]
  local orig_line = api.nvim_buf_get_lines(bufnr, orig_lineno - 1, orig_lineno, true)[1]
  local orig_nlines = api.nvim_buf_line_count(bufnr)
  local view = vfn.winsaveview()

  fn()

  -- note: this isn't 100% correct, if the lines change below the current one,
  -- the position won't be the same, but this is optmistic: if the file was
  -- already formatted before, the lines below will mostly do the right thing.
  local line_offset = api.nvim_buf_line_count(bufnr) - orig_nlines
  local lineno = orig_lineno + line_offset
  local col_offset = string.len(api.nvim_buf_get_lines(bufnr, lineno - 1, lineno, true)[1] or "") -
                       string.len(orig_line)
  view.lnum = lineno
  view.col = orig_colno + col_offset
  vfn.winrestview(view)
end

function M.once(fn)
  local result
  local called = false
  return function(...)
    if called then
      return result
    end
    called = true
    result = fn(...)
    return result
  end
end

return M
