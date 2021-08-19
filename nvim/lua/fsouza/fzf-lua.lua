local _fzf_lua = nil

local function fzf_lua()
  if _fzf_lua == nil then
    _fzf_lua = require('fzf-lua')
    _fzf_lua.setup({
      fzf_args = vim.env.FZF_DEFAULT_OPTS .. ' --border rounded';
      fzf_layout = 'default';
      buffers = {file_icons = false; git_icons = false};
      files = {file_icons = false; git_icons = false};
      grep = {file_icons = false; git_icons = false};
      oldfiles = {file_icons = false; git_icons = false};
      winopts = {win_height = 0.65; win_width = 0.90; win_border = false};
      previewers = {bat = {theme = 'monochrome'}};
    })
  end
  return _fzf_lua
end

return setmetatable({}, {
  __index = function(table, key)
    local value = fzf_lua()[key]
    rawset(table, key, value)
    return value
  end;
})
