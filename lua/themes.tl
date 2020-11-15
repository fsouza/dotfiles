local M = {}

local meta = {}
function meta:__index(key: string): number
  -- avoid dynamic requires: not good with tl.
  if key == 'popup' then
    M[key] = require('themes.popup')()
  else
    M[key] = require('themes.none')()
  end
  return M[key]
end

return setmetatable(M, meta)
