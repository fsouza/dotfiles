local vcmd = vim.cmd
local vfn = vim.fn

local M = {}

function M.fuzzy_here()
  local dir_path = vfn.expand('%:p:h')
  if vim.startswith(dir_path, '/') then
    vcmd('FzfFiles ' .. dir_path)
  end
end

function M.rg(input)
  input = input or vfn.input([[rg：]])
  if input ~= '' then
    local cmd =
      [[rg --column -n --hidden --no-heading --color=always -S --glob '!.git' --glob '!.hg' -- ]] ..
        vfn.shellescape(input)
    vfn['fzf#vim#grep'](cmd, true, vfn['fzf#vim#with_preview']())
  end
end

function M.rg_cword()
  M.rg(vfn.expand('<cword>'))
end

return M
