-- Set up basic color scheme settings
vim.o.termguicolors = true
vim.o.background = "light"
vim.g.colors_name = "none"

-- Define colors palette
local colors = {
  ["darker-gray"] = "#333333",
  ["dark-gray"] = "#5f5f5f",
  ["gray"] = "#afafaf",
  ["light-gray"] = "#d0d0d0",
  ["lighter-gray"] = "#dadada",
  ["black"] = "#262626",
  ["red"] = "#990000",
  ["brown"] = "#5f0000",
  ["white"] = "#f0f0eb",
  ["darker-white"] = "#bdbda6",
  ["gray-white"] = "#dcdcc8",
  ["pink"] = "#ffd7ff",
  ["orange"] = "#ffd787",
  ["blue"] = "#000066"
}

-- Basic highlight groups
local basic_groups = {
  {name = "CursorColumn", opts = {bg = colors["lighter-gray"]}},
  {name = "CursorLine", opts = {bg = colors["lighter-gray"]}},
  {name = "CursorLineNr", opts = {bold = true, fg = colors["black"]}},
  {name = "Directory", opts = {fg = colors["dark-gray"]}},
  {name = "LineNr", opts = {fg = colors["dark-gray"]}},
  {name = "MatchParen", opts = {bg = colors["light-gray"]}},
  {name = "Normal", opts = {fg = colors["black"]}},
  {name = "Floating", opts = {bg = colors["light-gray"], fg = colors["black"]}},
  {name = "Pmenu", opts = {bg = colors["darker-white"]}},
  {name = "PmenuSel", opts = {bg = colors["white"]}},
  {name = "SignColumn", opts = {bg = colors["lighter-gray"], fg = colors["black"]}},
  {name = "SpecialKey", opts = {fg = colors["dark-gray"]}},
  {name = "SpellBad", opts = {fg = colors["red"]}},
  {name = "TabLine", opts = {bg = colors["darker-white"], fg = colors["dark-gray"]}},
  {name = "TabLineFill", opts = {bg = colors["darker-white"]}},
  {name = "TabLineSel", opts = {fg = colors["dark-gray"]}},
  {name = "ErrorMsg", opts = {bg = colors["red"], fg = colors["white"]}},
  {name = "WarningMsg", opts = {fg = colors["brown"]}},
  {name = "Folded", opts = {bg = colors["lighter-gray"]}},
  {name = "FoldColumn", opts = {bg = colors["lighter-gray"]}},
  {name = "Error", opts = {fg = colors["red"]}},
  {name = "String", opts = {fg = colors["blue"]}},
  {name = "Comment", opts = {fg = colors["dark-gray"]}},
  {name = "Visual", opts = {bg = colors["gray"]}},
  {name = "VertSplit", opts = {fg = colors["black"]}},
  {name = "WinSeparator", opts = {fg = colors["black"]}},
  {name = "StatusLine", opts = {bg = colors["light-gray"], fg = colors["black"]}},
  {name = "LspCodeLens", opts = {fg = colors["gray"]}},
  {name = "LspInlayHint", opts = {fg = colors["gray"]}},
  {name = "LspCodeLensSeparator", opts = {fg = colors["gray"]}},
  {name = "StatusLineNC", opts = {bg = colors["light-gray"], fg = colors["black"]}},
  {name = "HlYank", opts = {bg = colors["orange"]}},
  {name = "IncSearch", opts = {link = "Visual"}},
  {name = "FidgetTask", opts = {link = "Normal"}}
}

-- Groups with no specific highlighting
local none_groups = {
  "Boolean", "Character", "Conceal", "Conditional", "Constant",
  "Debug", "Define", "Delimiter", "Exception", "Float",
  "Function", "FzfLuaHeaderBind", "FzfLuaHeaderText", "FzfLuaPathLineNr",
  "FzfLuaPathColNr", "Identifier", "Ignore", "Include", "Keyword",
  "Label", "Macro", "NonText", "Number", "Operator",
  "PmenuSbar", "PmenuThumb", "Question", "QuickFixLine", "Search",
  "PreCondit", "PreProc", "Repeat", "Special", "SpecialChar",
  "SpecialComment", "Statement", "StorageClass", "Structure", "Tag",
  "Todo", "Type", "Typedef", "Underlined", "htmlBold",
  "Title", "ModeMsg", "FloatBorder", "editorconfigInvalidProperty",
  "@text.literal", "@text.literal.block", "@markup.italic"
}

-- Pop-up related groups
local function setup_popup_groups()
  vim.api.nvim_set_hl(0, "NormalFloat", {link = "Pmenu"})
  vim.api.nvim_set_hl(0, "PopupNormal", {link = "Pmenu"})
  vim.api.nvim_set_hl(0, "PopupCursorLine", {link = "CursorLine"})
  vim.api.nvim_set_hl(0, "PopupCursorLineNr", {link = "PopupCursorLine"})
end

-- Groups with reverse attribute
local reverse_groups = {"Cursor", "MoreMsg"}

-- LSP reference groups
local lsp_ref_types = {"Text", "Read", "Write"}

-- LSP diagnostic groups
local diagnostic_levels = {"Error", "Warn", "Info", "Hint"}

-- Apply all highlighting
for _, group in ipairs(basic_groups) do
  vim.api.nvim_set_hl(0, group.name, group.opts)
end

for _, group_name in ipairs(none_groups) do
  vim.api.nvim_set_hl(0, group_name, {})
end

for _, group_name in ipairs(reverse_groups) do
  vim.api.nvim_set_hl(0, group_name, {reverse = true})
end

setup_popup_groups()

for _, ref_type in ipairs(lsp_ref_types) do
  vim.api.nvim_set_hl(0, "LspReference" .. ref_type, {bg = colors["gray-white"]})
end

local diagnostics_sign = {fg = colors["red"], bold = true}
local diagnostics_underline = {underline = true}

for _, level in ipairs(diagnostic_levels) do
  local diagn_group = "Diagnostic" .. level
  local sign_group = "DiagnosticSign" .. level
  local underline_group = "DiagnosticUnderline" .. level
  local floating_group = "DiagnosticFloating" .. level
  
  vim.api.nvim_set_hl(0, diagn_group, {})
  vim.api.nvim_set_hl(0, floating_group, {})
  vim.api.nvim_set_hl(0, underline_group, diagnostics_underline)
  vim.api.nvim_set_hl(0, sign_group, diagnostics_sign)
end