local api = vim.api
local lsp_util = vim.lsp.util
local helpers = require('fsouza.lib.nvim_helpers')

local M = {}

local debounced_notify = require('fsouza.lib.debounce').debounce(2000,
                                                                 vim.schedule_wrap(vim.notify))

local function on_progress_update()
  local mode = api.nvim_get_mode()
  if mode.mode ~= 'n' then
    return
  end

  local messages = lsp_util.get_progress_messages()

  local function format_message(msg)
    local prefix = ''
    if msg.title ~= '' then
      prefix = string.format('%s: ', msg.title)
    end

    if msg.name ~= '' then
      prefix = string.format('[%s] %s', msg.name, prefix)
    end

    local suffix = ''
    if msg.percentage then
      suffix = string.format(' (%s)', msg.percentage)
    end

    return string.format('%s%s%s', prefix, msg.message, suffix)
  end

  require('fsouza.tablex').foreach(messages, function(message)
    debounced_notify.call(format_message(message))
  end)
end

function M.on_attach()
  helpers.augroup('fsouza__lsp_progress', {
    {events = {'User LspProgressUpdate'}; command = helpers.fn_cmd(on_progress_update)};
  })
end

return M
