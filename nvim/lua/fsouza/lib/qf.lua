local function parse_line(line, map)
  local col_pattern = "^([a-zA-Z0-9/.~][^:]+):(%d+):(%d+):(.+)"
  local line_pattern = "^([a-zA-Z0-9/.~][^:]+):(%d+):(.+)"
  line = vim.trim(line)

  local filename, lnum, col, text = string.match(line, col_pattern)
  if filename then
    return map({
      filename = filename,
      lnum = tonumber(lnum),
      col = tonumber(col),
      text = text,
      type = "E",
    })
  else
    local filename, lnum, text = string.match(line, line_pattern)
    if filename then
      return map({
        filename = filename,
        lnum = tonumber(lnum),
        text = text,
        col = 1,
        type = "E",
      })
    else
      return nil
    end
  end
end

local function load_from_lines(lines, map)
  map = map or function(x)
    return x
  end
  local result = {}

  for _, line in ipairs(lines) do
    local item = parse_line(line, map)
    if item then
      table.insert(result, item)
    end
  end

  return result
end

local function set_from_lines(lines, opts)
  opts = opts or {}
  local list = load_from_lines(lines, opts.map)

  vim.fn.setqflist(list)

  if opts.open then
    vim.cmd.copen()
  end

  if opts.jump_to_first then
    vim.cmd.cfirst()
  end

  return #list > 0
end

local function set_from_contents(content, opts)
  local lines = vim.split(content, "\n", { plain = true, trimempty = true })
  return set_from_lines(lines, opts)
end

local function set_from_visual_selection(opts)
  local nvim_helpers = require("fsouza.lib.nvim-helpers")
  local lines = nvim_helpers.get_visual_selection_contents()
  return set_from_lines(lines, opts)
end

return {
  set_from_visual_selection = set_from_visual_selection,
  set_from_contents = set_from_contents,
}
