local function augroup_name(bufnr)
  return "fsouza__lsp_shell-post_" .. bufnr
end

local function on_attach(bufnr)
  local augroup = require("fsouza.lib.nvim-helpers").augroup
  
  augroup(augroup_name(bufnr), {
    {
      events = {"FileChangedShellPost"},
      targets = {string.format("<buffer=%d>", bufnr)},
      callback = function()
        local sync = require("fsouza.lsp.sync")
        sync.notify_clients(bufnr)
      end
    }
  })
end

return {
  on_attach = on_attach
}