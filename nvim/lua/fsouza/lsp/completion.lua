local M = {}

local function setup(autocomplete, bufnr)
  require('compe').setup({enabled = true; autocomplete = autocomplete; source = {nvim_lsp = true}},
                         bufnr)
end

function M.enable_autocomplete(bufnr)
  setup(true, bufnr)
end

function M.disable_autocomplete(bufnr)
  setup(false, bufnr)
end

function M.on_attach(bufnr)
  setup(false, bufnr)
end

return M
