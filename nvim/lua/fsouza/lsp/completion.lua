local api = vim.api
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
  require('fsouza.color').add_popup_cb(function()
    local wins = api.nvim_list_wins()
    for _, winid in ipairs(wins) do
      if api.nvim_win_is_valid(winid) and pcall(api.nvim_win_get_var, winid, 'compe_documentation') then
        return winid
      end
    end
  end)
end

return M
