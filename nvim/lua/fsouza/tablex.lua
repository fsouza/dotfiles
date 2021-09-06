local tablex = {}

local pl_tablex = require('pl.tablex')

function tablex.flat_map(fn, t)
  local result = {}
  pl_tablex.foreach(t, function(value, key)
    pl_tablex.foreach(fn(value, key), function(output)
      table.insert(result, output)
    end)
  end)
  return result
end

function tablex.filter_map(fn, t)
  local result = {}
  pl_tablex.foreach(t, function(value, key)
    local r = fn(value, key)
    if r then
      table.insert(result, r)
    end
  end)
  return result
end

tablex.flatten = vim.tbl_flatten

function tablex.exists(t, pred)
  return pl_tablex.find_if(t, pred) ~= nil
end

function tablex.find_value_if(t, pred)
  local idx = pl_tablex.find_if(t, pred) ~= nil
  if idx == nil then
    return nil
  end
  return t[idx]
end

return setmetatable(tablex, {
  __index = function(table, key)
    local value = pl_tablex[key]
    rawset(table, key, value)
    return value
  end;
})
