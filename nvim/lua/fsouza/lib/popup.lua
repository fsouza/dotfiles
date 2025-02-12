local function find_other(win_var_identifier)
  local winids = {}
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    if vim.w[winid][win_var_identifier] then
      table.insert(winids, winid)
    end
  end
  
  assert(#winids <= 1)
  return winids[1]
end

local function set_content(bufnr, lines, opts)
  vim.bo[bufnr].readonly = false
  vim.bo[bufnr].modifiable = true
  
  local markdown = opts.markdown
  local width = opts.width
  local height = opts.height
  
  if markdown then
    vim.lsp.util.stylize_markdown(bufnr, lines, {
      width = width, 
      height = height, 
      separator = true
    })
  else
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)
  end
  
  vim.bo[bufnr].readonly = true
  vim.bo[bufnr].modifiable = false
end

local function update_existing(winid, lines, opts)
  local bufnr = vim.api.nvim_win_get_buf(winid)
  set_content(bufnr, lines, opts)
  vim.api.nvim_win_set_width(winid, opts.width)
  vim.api.nvim_win_set_height(winid, opts.height)
  return winid, bufnr
end

local function do_open(lines, opts)
  local bufnr = vim.api.nvim_create_buf(false, true)
  local win_opts = opts.win_opts
  local wrap = opts.wrap
  local win_var_identifier = opts.win_var_identifier
  local markdown = opts.markdown
  
  local winid = vim.api.nvim_open_win(bufnr, false, win_opts)
  
  set_content(bufnr, lines, {
    markdown = markdown,
    width = win_opts.width,
    height = win_opts.height
  })
  
  vim.wo[winid].wrap = wrap == true
  vim.wo[winid].winhighlight = "Normal:PopupNormal,CursorLineNr:PopupCursorLineNr,CursorLine:PopupCursorLine"
  vim.w[winid][win_var_identifier] = true
  
  return winid, bufnr
end

local function open(opts)
  local lines = opts.lines
  local type_name = opts.type_name
  local markdown = opts.markdown
  local min_width = opts.min_width
  local max_width = opts.max_width
  local wrap = opts.wrap
  local update_if_exists = opts.update_if_exists
  
  local longest = 0
  for _, line in ipairs(lines) do
    longest = math.max(longest, #line)
  end
  longest = longest * 2
  
  min_width = min_width or 50
  max_width = max_width or (3 * min_width)
  
  local win_var_identifier = string.format("fsouza__popup-%s", type_name)
  local width = math.min(math.max(longest, min_width), max_width)
  local height = #lines
  
  local col = opts.right_col and (opts.right_col - width) or (opts.col or 0)
  
  local win_opts = {
    relative = opts.relative or "cursor",
    width = width,
    height = height,
    col = col,
    row = opts.row or 0,
    style = "minimal"
  }
  
  local other = find_other(win_var_identifier)
  if other then
    if update_if_exists then
      return update_existing(other, lines, {markdown = markdown, width = width, height = height})
    else
      vim.api.nvim_win_close(other, true)
      return do_open(lines, {
        win_opts = win_opts,
        wrap = wrap,
        win_var_identifier = win_var_identifier,
        markdown = markdown
      })
    end
  else
    return do_open(lines, {
      win_opts = win_opts,
      wrap = wrap,
      win_var_identifier = win_var_identifier,
      markdown = markdown
    })
  end
end

local function stylize(winid)
  vim.wo[winid].winhighlight = "Normal:PopupNormal,NormalFloat:PopupNormal,MatchParen:PopupNormal,FloatBorder:PopupNormal"
end

return {
  open = open,
  stylize = stylize
}