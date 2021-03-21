local api = vim.api

local M = {}

-- returns whether autoformatting is enabled.
--
-- For enabled, we first look at vim.b, then vim.g (and it defaults to true).
function M.is_enabled(bufnr)
  local _, buf_autoformat = pcall(api.nvim_buf_get_var, bufnr, 'autoformat')
  if buf_autoformat ~= nil then
    return buf_autoformat
  end
  if vim.g.autoformat ~= nil then
    return vim.g.autoformat
  end
  return true
end

local function toggle(ns)
  if ns.autoformat == false then
    ns.autoformat = true
  else
    ns.autoformat = false
  end
end

function M.toggle()
  toggle(vim.b)
end

function M.toggle_g()
  toggle(vim.g)
end

return M
