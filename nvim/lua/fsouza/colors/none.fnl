(local colors (require :fsouza.themes.colors))

(fn basics []
  [{:group "CursorColumn" :opts {:guibg colors.lighter-gray}}
   {:group "CursorLine" :opts {:guibg colors.lighter-gray}}
   {:group "CursorLineNr" :opts {:bold true :guibg colors.lighter-gray}}
   {:group "Directory" :opts {:guifg colors.dark-gray}}
   {:group "LineNr" :opts {:guibg colors.lighter-gray}}
   {:group "MatchParen" :opts {:guibg colors.light-gray}}
   {:group "Normal" :opts {:guifg colors.black}}
   {:group "Floating" :opts {:guibg colors.light-gray :guifg colors.black}}
   {:group "Pmenu" :opts {:guibg colors.gray}}
   {:group "SignColumn" :opts {:guibg colors.lighter-gray :guifg colors.black}}
   {:group "SpecialKey" :opts {:guifg colors.dark-gray}}
   {:group "SpellBad" :opts {:guifg colors.red}}
   {:group "TabLine" :opts {:guibg colors.gray :guifg colors.dark-gray}}
   {:group "TabLineFill" :opts {:guibg colors.gray}}
   {:group "TabLineSel" :opts {:guifg colors.dark-gray}}
   {:group "ErrorMsg" :opts {:guibg colors.red :guifg colors.white}}
   {:group "WarningMsg" :opts {:guifg colors.brown}}
   {:group "Folded" :opts {:guibg colors.lighter-gray}}
   {:group "FoldColumn" :opts {:guibg colors.lighter-gray}}
   {:group "Error" :opts {:guifg colors.red}}
   {:group "String" :opts {:guifg colors.blue}}
   {:group "Comment" :opts {:guifg colors.dark-gray}}])

(fn noners []
  (let [groups ["Boolean" "Character" "Conceal" "Conditional" "Constant"
                "Debug" "Define" "Delimiter" "Exception" "Float" "Function" "Identifier"
                "Ignore" "Include" "Keyword" "Label" "Macro" "NonText" "Number" "Operator"
                "PmenuSbar" "PmenuSel" "PmenuThumb" "Question" "Search" "PreCondit" "PreProc"
                "Repeat" "Special" "SpecialChar" "SpecialComment" "Statement" "StorageClass"
                "Structure" "Tag" "Todo" "Type" "Typedef" "Underlined" "htmlBold"
                "Title" "ModeMsg" "FloatBorder"]]
    (icollect [_ group-name (ipairs groups)]
      {:group group-name :opts {:gui "NONE"}})))

(fn reversers []
  (let [groups ["MoreMsg" "StatusLine" "StatusLineNC" "Visual"]]
    (icollect [_ group-name (ipairs groups)]
      {:group group-name :opts {:gui "reverse"}})))

(fn lsp-references []
  (let [ref-types ["Text" "Read" "Write"]]
    (icollect [_ ref-type (ipairs ref-types)]
      {:group (.. "LspReference" ref-type)
       :opts {:guibg colors.light-gray}})))

(fn lsp-diagnostics []
  (let [diagnostics-floating {:link "Normal"}
        diagnostics-sign {:guifg colors.red :guibg colors.lighter-gray :bold true}
        levels ["Error" "Warn" "Info" "Hint"]
        output []]
    (each [_ level (ipairs levels)]
      (let [sign-group (.. "DiagnosticSign" level)
            floating-group (.. "DiagnosticFloating" level)]
        (table.insert {:group sign-group :opts diagnostics-sign})
        (table.insert {:group floating-group :opts diagnostics-floating})))))

(fn lsp-codelens []
  {:group "LspCodeLensVirtualText" :opts {:guifg colors.gray}})

(fn custom-groups []
  {:group "HlYank" :opts {:guibg colors.orange}})

(do
  (vim.cmd "highlight clear")
  (tset vim.o :termguicolors true)
  (tset vim.o :background "light"))
