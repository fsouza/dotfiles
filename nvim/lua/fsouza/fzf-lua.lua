local _fzf_lua = nil

local function fzf_lua()
  if _fzf_lua == nil then
    local config = require('fzf-lua.config')
    config.globals.buffers.file_icons = false
    config.globals.buffers.git_icons = false
    config.globals.default_previewer = 'cat'
    config.globals.files.file_icons = false
    config.globals.files.git_icons = false
    config.globals.fzf_layout = 'default'
    config.globals.grep.file_icons = false
    config.globals.grep.git_icons = false
    config.globals.oldfiles.file_icons = false
    config.globals.oldfiles.git_icons = false
    config.globals.previewers.cat.args = ''
    config.globals.winopts.win_height = 0.65
    config.globals.winopts.win_width = 0.90
    _fzf_lua = require('fzf-lua')
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
