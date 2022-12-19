(macro basics []
  (let [groups [{:name :CursorColumn :opts {:bg `colors.lighter-gray}}
                {:name :CursorLine :opts {:bg `colors.lighter-gray}}
                {:name :CursorLineNr :opts {:bold true :fg `colors.black}}
                {:name :Directory :opts {:fg `colors.dark-gray}}
                {:name :LineNr :opts {:fg `colors.dark-gray}}
                {:name :MatchParen :opts {:bg `colors.light-gray}}
                {:name :Normal :opts {:fg `colors.black}}
                {:name :Floating
                 :opts {:bg `colors.light-gray :fg `colors.black}}
                {:name :Pmenu :opts {:bg `colors.gray}}
                {:name :SignColumn
                 :opts {:bg `colors.lighter-gray :fg `colors.black}}
                {:name :SpecialKey :opts {:fg `colors.dark-gray}}
                {:name :SpellBad :opts {:fg `colors.red}}
                {:name :TabLine :opts {:bg `colors.gray :fg `colors.dark-gray}}
                {:name :TabLineFill :opts {:bg `colors.gray}}
                {:name :TabLineSel :opts {:fg `colors.dark-gray}}
                {:name :ErrorMsg :opts {:bg `colors.red :fg `colors.white}}
                {:name :WarningMsg :opts {:fg `colors.brown}}
                {:name :Folded :opts {:bg `colors.lighter-gray}}
                {:name :FoldColumn :opts {:bg `colors.lighter-gray}}
                {:name :Error :opts {:fg `colors.red}}
                {:name :String :opts {:fg `colors.blue}}
                {:name :Comment :opts {:fg `colors.dark-gray}}
                {:name :Visual :opts {:bg `colors.gray}}
                {:name :VertSplit :opts {:fg `colors.black}}
                {:name :WinSeparator :opts {:fg `colors.black}}
                {:name :StatusLine
                 :opts {:bg `colors.light-gray :fg `colors.black}}
                {:name :LspCodeLens :opts {:fg `colors.gray}}
                {:name :LspCodeLensSeparator :opts {:fg `colors.gray}}
                {:name :StatusLineNC
                 :opts {:bg `colors.light-gray :fg `colors.black}}
                {:name :HlYank :opts {:bg `colors.orange}}
                {:name :FidgetTask :opts {:link :Normal}}]]
    (icollect [_ group (ipairs groups)]
      `(vim.api.nvim_set_hl 0 ,group.name ,group.opts))))

(macro noners []
  (let [groups [:Boolean
                :Character
                :Conceal
                :Conditional
                :Constant
                :Debug
                :Define
                :Delimiter
                :Exception
                :Float
                :Function
                :Identifier
                :Ignore
                :Include
                :Keyword
                :Label
                :Macro
                :NonText
                :Number
                :Operator
                :PmenuSbar
                :PmenuSel
                :PmenuThumb
                :Question
                :Search
                :PreCondit
                :PreProc
                :Repeat
                :Special
                :SpecialChar
                :SpecialComment
                :Statement
                :StorageClass
                :Structure
                :Tag
                :Todo
                :Type
                :Typedef
                :Underlined
                :htmlBold
                :Title
                :ModeMsg
                :FloatBorder]]
    (icollect [_ group-name (ipairs groups)]
      `(vim.api.nvim_set_hl 0 ,group-name {}))))

(macro popup []
  `(do
     (vim.api.nvim_set_hl 0 :PopupNormal {:link :Pmenu})
     (vim.api.nvim_set_hl 0 :PopupCursorLine {:link :CursorLine})
     (vim.api.nvim_set_hl 0 :PopupCursorLineNr {:link :PopupCursorLine})))

(macro reversers []
  (let [groups [:Cursor :MoreMsg]]
    (icollect [_ group-name (ipairs groups)]
      `(vim.api.nvim_set_hl 0 ,group-name {:reverse true}))))

(macro lsp-references []
  (let [ref-types [:Text :Read :Write]]
    (icollect [_ ref-type (ipairs ref-types)]
      `(vim.api.nvim_set_hl 0 ,(.. :LspReference ref-type)
                            {:bg colors.light-gray}))))

(macro lsp-diagnostics []
  (let [diagnostics-sign `{:fg colors.red :bold true}
        diagnostics-underline `{:underline true}
        levels [:Error :Warn :Info :Hint]]
    (icollect [_ level (ipairs levels)]
      `(let [diagn-group# ,(.. :Diagnostic level)
             sign-group# ,(.. :DiagnosticSign level)
             underline-group# ,(.. :DiagnosticUnderline level)
             floating-group# ,(.. :DiagnosticFloating level)]
         (vim.api.nvim_set_hl 0 diagn-group# {})
         (vim.api.nvim_set_hl 0 floating-group# {})
         (vim.api.nvim_set_hl 0 underline-group# ,diagnostics-underline)
         (vim.api.nvim_set_hl 0 sign-group# ,diagnostics-sign)))))

(do
  (vim.api.nvim_set_option_value :termguicolors true {:scope :global})
  (vim.api.nvim_set_option_value :background :light {:scope :global})
  (tset vim.g :colors_name :none)
  (let [colors {:darker-gray "#333333"
                :dark-gray "#5f5f5f"
                :gray "#afafaf"
                :light-gray "#d0d0d0"
                :lighter-gray "#dadada"
                :black "#262626"
                :red "#990000"
                :brown "#5f0000"
                :white "#ececec"
                :pink "#ffd7ff"
                :orange "#ffd787"
                :blue "#000066"}]
    (basics colors)
    (noners)
    (reversers)
    (popup)
    (lsp-references)
    (lsp-diagnostics)))
