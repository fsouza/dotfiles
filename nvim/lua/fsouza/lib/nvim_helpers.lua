local M = {fns = {}}

local api = vim.api
local vcmd = vim.cmd

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
    fn = require('pl.func').bind1(api.nvim_buf_set_keymap, bufnr)
  end

  local tablex = require('fsouza.tablex')
  tablex.foreach(mappings, function(rules, mode)
    tablex.foreach(rules, function(m)
      fn(mode, m.lhs, m.rhs, m.opts or {})
    end)
  end)
end

function M.remove_mappings(mappings, bufnr)
  local fn = api.nvim_del_keymap
  if bufnr then
    fn = require('pl.func').bind1(api.nvim_buf_del_keymap, bufnr)
  end

  local tablex = require('fsouza.tablex')
  tablex.foreach(mappings, function(rules, mode)
    tablex.foreach(rules, function(m)
      fn(mode, m.lhs)
    end)
  end)
end

function M.augroup(name, commands)
  local tablex = require('fsouza.tablex')

  vcmd('augroup ' .. name)
  vcmd('autocmd!')
  tablex.foreach(commands, function(c)
    vcmd(string.format('autocmd %s %s %s %s', table.concat(c.events, ','),
                       table.concat(c.targets or {}, ','), table.concat(c.modifiers or {}, ' '),
                       c.command))
  end)
  vcmd('augroup END')
end

function M.reset_augroup(name)
  M.augroup(name, {})
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
