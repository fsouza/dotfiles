local mapping_per_buf = {}

local function augroup_name(bufnr)
  return "fsouza__lsp_codelens_" .. bufnr
end

local function on_detach(bufnr)
  local mappings = mapping_per_buf[bufnr]
  
  if vim.api.nvim_buf_is_valid(bufnr) and mappings then
    vim.keymap.del("n", mappings, {buffer = bufnr})
  end
  
  local augroup_id = augroup_name(bufnr)
  local buf_diagnostic = require("fsouza.lsp.buf-diagnostic")
  local nvim_helpers = require("fsouza.lib.nvim-helpers")
  
  nvim_helpers.reset_augroup(augroup_id)
  buf_diagnostic.unregister_hook(augroup_id)
end

local function on_attach(opts)
  local bufnr = opts.bufnr
  local augroup_id = augroup_name(bufnr)
  
  local function refresh()
    vim.lsp.codelens.refresh({bufnr = bufnr})
  end
  
  local augroup = require("fsouza.lib.nvim-helpers").augroup
  
  mapping_per_buf[bufnr] = opts.mapping
  vim.schedule(refresh)
  
  augroup(augroup_id, {
    {
      events = {"InsertLeave", "BufWritePost"},
      targets = {string.format("<buffer=%d>", bufnr)},
      callback = refresh
    }
  })
  
  vim.schedule(function()
    local buf_diagnostic = require("fsouza.lsp.buf-diagnostic")
    buf_diagnostic.register_hook(augroup_id, refresh)
    
    vim.api.nvim_buf_attach(bufnr, false, {
      on_detach = function() on_detach(bufnr) end
    })
  end)
  
  if opts.mapping then
    vim.keymap.set("n", opts.mapping, vim.lsp.codelens.run, 
                  {silent = true, buffer = bufnr})
  end
end

return {
  on_attach = on_attach
}