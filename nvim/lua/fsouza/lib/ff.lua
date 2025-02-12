local features = {}

local function disable(feature)
  features[feature] = false
end

local function enable(feature)
  features[feature] = true
end

local function is_enabled(feature, default_value)
  local v = features[feature]
  if v ~= nil then
    return v
  else
    return default_value
  end
end

return {
  disable = disable,
  enable = enable,
  is_enabled = is_enabled,
}
