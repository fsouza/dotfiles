local function fmt_task(task_name, message, percentage)
  local mid = ""
  if percentage then
    mid = string.format(" (%s%%)", percentage)
  end
  
  local suffix = ""
  if task_name and task_name ~= "" then
    suffix = string.format(" [%s]", task_name)
  end
  
  return message .. mid .. suffix
end

local fidget = require("fidget")
fidget.setup({window = {blend = 0}, fmt = {task = fmt_task}})

local enabled = true
local rbuf = vim.ringbuf(128)
local debounce = require("fsouza.lib.debounce")
local handler = debounce.debounce(
  500,
  vim.schedule_wrap(vim.lsp.handlers["$/progress"])
)
local augroup = require("fsouza.lib.nvim-helpers").augroup

local function drain_rbuf()
  for entry in vim.iter(rbuf) do
    handler.call(entry.err, entry.result, entry.context)
  end
end

vim.lsp.handlers["$/progress"] = function(err, result, context)
  if enabled then
    handler.call(err, result, context)
  else
    rbuf:push({err = err, result = result, context = context})
  end
end

augroup("fsouza__auto_disable_progress", {
  {
    events = {"InsertLeave"},
    targets = {"*"},
    callback = function()
      drain_rbuf()
      enabled = true
    end
  },
  {
    events = {"InsertEnter"},
    targets = {"*"},
    callback = function()
      enabled = false
      handler.clear()
      vim.cmd.FidgetClose()
    end
  }
})