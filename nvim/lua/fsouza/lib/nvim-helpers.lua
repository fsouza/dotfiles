local function wrap_callback(cb)
  if cb then
    return function(...)
      cb(...)
      return nil
    end
  else
    return nil
  end
end

local function augroup(name, commands)
  local group = vim.api.nvim_create_augroup(name, { clear = true })

  for _, opts in ipairs(commands) do
    local targets = opts.targets
    local command = opts.command
    local callback = opts.callback
    local once = opts.once
    local events = opts.events

    vim.api.nvim_create_autocmd(events, {
      pattern = targets,
      command = command,
      callback = wrap_callback(callback),
      group = group,
      once = once,
    })
  end
end

local function once(f)
  local result = nil
  local called = false

  return function(...)
    if not called then
      called = true
      result = f(...)
      return result
    end
    return result
  end
end

-- Provides a wrapper to a function that rewrites the current buffer, and does
-- a best effort to restore the cursor position.
local function rewrite_wrap(f)
  local winid = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_get_current_buf()
  local orig_lineno, orig_colno = unpack(vim.api.nvim_win_get_cursor(winid))
  local orig_line = vim.api.nvim_buf_get_lines(bufnr, orig_lineno - 1, orig_lineno, true)[1]
  local orig_nlines = vim.api.nvim_buf_line_count(bufnr)

  f()

  local line_offset = vim.api.nvim_buf_line_count(bufnr) - orig_nlines
  local lineno = orig_lineno + line_offset
  local new_line = vim.api.nvim_buf_get_lines(bufnr, lineno - 1, lineno, true)[1] or ""
  local col_offset = string.len(new_line) - string.len(orig_line)

  vim.api.nvim_win_set_cursor(winid, {
    math.max(lineno, 1),
    math.min(math.max(0, orig_colno + col_offset), vim.v.maxcol),
  })
end

local function get_visual_selection_range()
  local mode = vim.api.nvim_get_mode().mode
  local _, srow, scol, _ = unpack(vim.fn.getpos("."))
  local _, erow, ecol, _ = unpack(vim.fn.getpos("v"))

  if srow < erow then
    return { srow, scol, erow, ecol }
  elseif srow > erow then
    return { erow, ecol, srow, scol }
  else
    if scol <= ecol then
      return { srow, scol, erow, ecol }
    else
      return { erow, ecol, srow, scol }
    end
  end
end

local function get_visual_selection_contents()
  local mode = vim.api.nvim_get_mode().mode
  return vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })
end

local function hash_buffer(bufnr)
  local sha1 = require("sha1")
  local lines = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, true), "\n")
  return sha1.sha1(lines)
end

return {
  reset_augroup = function(name)
    return vim.api.nvim_create_augroup(name, { clear = true })
  end,
  augroup = augroup,
  once = once,
  rewrite_wrap = rewrite_wrap,
  get_visual_selection_contents = get_visual_selection_contents,
  get_visual_selection_range = get_visual_selection_range,
  hash_buffer = hash_buffer,
}
