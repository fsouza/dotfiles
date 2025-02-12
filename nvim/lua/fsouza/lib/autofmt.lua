local function is_enabled(bufnr)
  local buf_autoformat = vim.b[bufnr].autoformat
  if buf_autoformat ~= nil then
    return buf_autoformat
  elseif vim.g.autoformat ~= nil then
    return vim.g.autoformat
  else
    return true
  end
end

local function toggle(ns)
  if ns.autoformat == false then
    ns.autoformat = true
  else
    ns.autoformat = false
  end
end

return {
  is_enabled = is_enabled,
  toggle = function() toggle(vim.b) end,
  toggle_g = function() toggle(vim.g) end
}