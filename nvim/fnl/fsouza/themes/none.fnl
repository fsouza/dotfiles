(import-macros {: if-nil} :fsouza)

(local colors (require "fsouza.themes.colors"))

(fn basics [ns]
  (vim.api.nvim_set_hl ns "CursorColumn" {:bg colors.lighter-gray})
  (vim.api.nvim_set_hl ns "CursorLine" {:bg colors.lighter-gray})
  (vim.api.nvim_set_hl ns "CursorLineNr" {:bold true :bg colors.lighter-gray})
  (vim.api.nvim_set_hl ns "Directory" {:fg colors.dark-gray})
  (vim.api.nvim_set_hl ns "LineNr" {:bg colors.lighter-gray})
  (vim.api.nvim_set_hl ns "MatchParen" {:bg colors.light-gray})
  (vim.api.nvim_set_hl ns "Normal" {:fg colors.black})
  (vim.api.nvim_set_hl ns "Floating" {:bg colors.light-gray :fg colors.black})
  (vim.api.nvim_set_hl ns "Pmenu" {:bg colors.gray})
  (vim.api.nvim_set_hl ns "SignColumn" {:bg colors.lighter-gray :fg colors.black})
  (vim.api.nvim_set_hl ns "SpecialKey" {:fg colors.dark-gray})
  (vim.api.nvim_set_hl ns "SpellBad" {:fg colors.red})
  (vim.api.nvim_set_hl ns "TabLine" {:bg colors.gray :fg colors.dark-gray})
  (vim.api.nvim_set_hl ns "TabLineFill" {:bg colors.gray})
  (vim.api.nvim_set_hl ns "TabLineSel" {:fg colors.dark-gray})
  (vim.api.nvim_set_hl ns "ErrorMsg" {:bg colors.red :fg colors.white})
  (vim.api.nvim_set_hl ns "WarningMsg" {:fg colors.brown})
  (vim.api.nvim_set_hl ns "Folded" {:bg colors.lighter-gray})
  (vim.api.nvim_set_hl ns "FoldColumn" {:bg colors.lighter-gray})
  (vim.api.nvim_set_hl ns "Error" {:fg colors.red}))

(fn noners [ns]
  (let [groups ["Boolean" "Character" "Comment" "Conceal" "Conditional" "Constant"
                "Debug" "Define" "Delimiter" "Exception" "Float" "Function" "Identifier"
                "Ignore" "Include" "Keyword" "Label" "Macro" "NonText" "Number" "Operator"
                "PmenuSbar" "PmenuSel" "PmenuThumb" "Question" "Search" "PreCondit" "PreProc"
                "Repeat" "Special" "SpecialChar" "SpecialComment" "Statement" "StorageClass"
                "String" "Structure" "Tag" "Todo" "Type" "Typedef" "Underlined" "htmlBold"
                "Title" "ModeMsg" "CmpDocumentationBorder" "FloatBorder"]]
    (each [_ group (ipairs groups)]
      (vim.api.nvim_set_hl ns group {}))))

(fn reversers [ns]
  (let [groups ["MoreMsg" "StatusLine" "StatusLineNC" "Visual"]]
    (each [_ group (ipairs groups)]
      (vim.api.nvim_set_hl ns group {:reverse true}))))

(fn setup-lsp-references [ns]
  (let [ref-types ["Text" "Read" "Write"]]
    (each [_ ref-type (ipairs ref-types)]
      (vim.api.nvim_set_hl ns (.. "LspReference" ref-type) {:bg colors.light-gray}))))

(fn setup-lsp-diagnostics [ns]
  (let [diagnostics-floating {:link "Normal"}
        diagnostics-sign {:fg colors.red :bg colors.lighter-gray :bold true}
        levels ["Error" "Warn" "Info" "Hint"]]
    (each [_ level (ipairs levels)]
      (let [sign-group (.. "DiagnosticSign" level)
            floating-group (.. "DiagnosticFloating" level)]
        (vim.api.nvim_set_hl ns sign-group diagnostics-sign)
        (vim.api.nvim_set_hl ns floating-group diagnostics-floating)))))

(fn setup-lsp-codelens [ns]
  (vim.api.nvim_set_hl ns "LspCodeLensVirtualText" {:fg colors.gray}))

(fn language-highlights [ns]
  (setup-lsp-diagnostics ns)
  (setup-lsp-references ns)
  (setup-lsp-codelens ns))

(fn custom-groups [ns]
  (vim.api.nvim_set_hl ns "HlYank" {:bg colors.orange}))

(fn [name]
  (let [ns (vim.api.nvim_create_namespace (if-nil name "fsouza__none"))]
    (basics ns)
    (noners ns)
    (reversers ns)
    (language-highlights ns)
    (custom-groups ns)
    ns))
