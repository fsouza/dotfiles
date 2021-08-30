local _telescope = nil

local function should_qf(selected)
  if #selected <= 2 then
    return false
  end

  for _, sel in ipairs(selected) do
    if string.match(sel, '^.+:%d+:%d+:') then
      return true
    end
  end

  return false
end

local function telescope()
  if _telescope == nil then
    _telescope = require('telescope')

    _telescope.setup {
      extensions = {
        fzf = {
          fuzzy = true;
          override_generic_sorter = false;
          override_file_sorter = true;
          case_mode = 'smart_case';
        };
      };
    }
    _telescope.load_extension('fzf')
  end
  return _telescope
end

return setmetatable({}, {
  __index = function(table, key)
    local value = telescope()[key]
    rawset(table, key, value)
    return value
  end;
})
