local test_checkers = {}

local function is_test(fname)
  local path = require("fsouza.lib.path")
  local ext = path.extension(fname)
  local ext_checkers = test_checkers[ext] or {}
  
  for _, checker in pairs(ext_checkers) do
    if checker(fname) then
      return true
    end
  end
  
  return false
end

local function do_filter(items)
  local lineno = vim.api.nvim_win_get_cursor(0)[1]
  local filtered_items = {}
  
  for _, item in ipairs(items) do
    if item.lnum ~= lineno then
      table.insert(filtered_items, item)
    end
  end
  
  if is_test(vim.api.nvim_buf_get_name(0)) then
    return filtered_items
  else
    local items2 = vim.deepcopy(filtered_items)
    local all_tests = true
    
    for _, item in ipairs(items2) do
      if not is_test(item.filename) then
        all_tests = false
        break
      end
    end
    
    if all_tests then
      return filtered_items
    else
      local non_test_items = {}
      for _, item in ipairs(filtered_items) do
        if not is_test(item.filename) then
          table.insert(non_test_items, item)
        end
      end
      return non_test_items
    end
  end
end

local function filter_references(items)
  if vim.islist(items) then
    if #items > 1 then
      return do_filter(items)
    else
      return items
    end
  else
    return items
  end
end

local function register_test_checker(ext, name, checker)
  local ext_checkers = test_checkers[ext] or {}
  ext_checkers[name] = checker
  test_checkers[ext] = ext_checkers
end

local function on_list(list)
  local fuzzy = require("fsouza.lib.fuzzy")
  list.items = filter_references(list.items)
  fuzzy.lsp_on_list(list)
end

return {
  register_test_checker = register_test_checker,
  on_list = on_list
}