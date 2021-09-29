(fn [name]
  (let [colors (require "fsouza.themes.colors")
        none-theme-factory (require "fsouza.themes.none")
        none-theme (none-theme-factory (vim.F.if_nil name "fsouza__popup"))]
    (vim.api.nvim_set_hl none-theme "Normal" {:fg colors.black :bg colors.gray})
    (vim.api.nvim_set_hl none-theme "LineNr" {})
    (vim.api.nvim_set_hl none-theme "CursorLine" {:bg colors.lighter-gray})
    (vim.api.nvim_set_hl none-theme "CursorLineNr" {:bold true :bg colors.lighter-gray})
    none-theme))
