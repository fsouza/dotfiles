-- this is very similar to the wrappper for fzf-lua. No reason to generalize
-- with only 2 use-cases, but once we have a third one, we should go for it.
local _lspconfig = nil

local function lspconfig()
  if _lspconfig == nil then
    vim.cmd([[packadd! nvim-lspconfig]])

    _lspconfig = require('lspconfig')
  end

  return _lspconfig
end

return setmetatable({}, {
  __index = function(table, key)
    local value = lspconfig()[key]
    rawset(table, key, value)
    return value
  end;
})
