local api = vim.api

local M = {}

local debouncers = {}

local hooks = {}

function M.buf_clear_all_diagnostics()
  vim.diagnostic.hide()
end

-- This is a workaround because the default lsp client doesn't let us hook into
-- textDocument/didChange like coc.nvim does.
local function exec_hooks()
  require("fsouza.tablex").foreach(hooks, function(fn)
    fn()
  end)
end

local function make_handler()
  local handler = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
    underline = true;
    virtual_text = false;
    signs = true;
    update_in_insert = true;
  })

  return function(err, result, context, ...)
    vim.schedule(exec_hooks)
    vim.diagnostic.reset(context.client_id, context.bufnr)
    handler(err, result, context, ...)
  end
end

function M.register_hook(id, fn)
  hooks[id] = fn
end

function M.unregister_hook(id)
  hooks[id] = nil
end

function M.publish_diagnostics(err, result, context, ...)
  if not result then
    return
  end
  local uri = result.uri
  local bufnr = vim.uri_to_bufnr(uri)
  if not bufnr then
    return
  end
  context.bufnr = bufnr

  local debouncer_key = string.format("%d/%s", context.client_id, uri)
  local _handler = make_handler()
  local handler = debouncers[debouncer_key]

  if handler == nil then
    local interval = vim.b.lsp_diagnostic_debouncing_ms or 250
    handler = require("fsouza.lib.debounce").debounce(interval, vim.schedule_wrap(_handler))
    debouncers[debouncer_key] = handler
    api.nvim_buf_attach(bufnr, false, {
      on_detach = function(_)
        handler.stop()
        debouncers[debouncer_key] = nil
      end;
    })
  end

  handler.call(err, result, context, ...)
end

return M
