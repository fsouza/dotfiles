local helpers = require('fsouza.lib.nvim_helpers')

local api = vim.api
local vfn = vim.fn

local M = {}

local debouncers = {}

local hooks = {}

function M.buf_clear_all_diagnostics()
  vim.diagnostic.hide()
end

-- This is a workaround because the default lsp client doesn't let us hook into
-- textDocument/didChange like coc.nvim does.
local function exec_hooks()
  require('fsouza.tablex').foreach(hooks, function(fn)
    fn()
  end)
end

local redefine_signs = helpers.once(function(cb)
  local levels = {'Error'; 'Warning'; 'Info'; 'Hint'}
  require('fsouza.tablex').foreach(levels, function(level)
    local sign_name = 'DiagnosticSign' .. level
    vfn.sign_define(sign_name, {text = ''; texthl = sign_name; numhl = sign_name})
  end)
  cb()
end)

local function make_handler()
  local handler = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
    underline = true;
    virtual_text = false;
    signs = true;
    update_in_insert = true;
  })
  return function(err, result, context, config)
    vim.schedule(exec_hooks)
    vim.diagnostic.reset(context.client_id, context.bufnr)
    handler(err, result, context, config)
    if result and vim.tbl_islist(result.diagnostics) and #result.diagnostics > 0 then
      vim.schedule(function()
        redefine_signs(function()
          vim.diagnostic.reset(context.client_id, context.bufnr)
          handler(err, result, context, config)
        end)
      end)
    end
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

  local debouncer_key = string.format('%d/%s', context.client_id, uri)
  local _handler = make_handler()
  local handler = debouncers[debouncer_key]

  if handler == nil then
    local interval = vim.b.lsp_diagnostic_debouncing_ms or 250
    handler = require('fsouza.lib.debounce').debounce(interval, vim.schedule_wrap(_handler))
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
