(import-macros {: vim-schedule} :helpers)

(global prequire (vim.F.nil_wrap require))

(global config-dir (vim.fn.expand "~/.dotfiles/nvim"))

(fn initial-mappings []
  (let [helpers (require :fsouza.lib.nvim-helpers)]
    (helpers.create-mappings {:n [{:lhs "Q" :rhs ""}
                                  {:lhs "<Space>" :rhs ""}
                                  {:lhs "<c-t>" :rhs ""}]}))
  (tset vim.g :mapleader " "))

(fn hererocks []
  (let [lua-version (string.gsub _G._VERSION "Lua " "")
        cache-dir (vim.fn.stdpath "cache")
        hererocks-path (.. cache-dir "/hr")
        share-path (.. hererocks-path "/share/lua/" lua-version)
        lib-path (.. hererocks-path "/lib/lua/" lua-version)]
    (tset package :path (table.concat [(.. share-path "/?.lua") (.. share-path "/?/init.lua") package.path] ";"))
    (tset package :cpath (table.concat [(.. lib-path "/?.so") package.cpath] ";"))))

(fn add-paqs-opt-to-path []
  (let [path (require :pl.path)
        packed (require :fsouza.packed)
        opt-dir (path.join packed.paq-dir "opt")]
    (each [_ paq (ipairs packed.paqs)]
      (when (and paq.opt paq.as)
        (let [paq-dir (path.join opt-dir paq.as)]
          (tset package :path (table.concat [package.path
                                             (path.join paq-dir "lua" "?.lua")
                                             (path.join paq-dir "lua" "?" "?.lua")
                                             (path.join paq-dir "lua" "?" "init.lua")] ";")))))))

(fn set-neovim-global-vars []
  (let [vars {:netrw_home (vim.fn.stdpath "data")
              :netrw_banner 0
              :netrw_liststyle 3
              :surround_no_insert_mappings true
              :user_emmet_mode "i"
              :user_emmet_leader_key "<C-x>"
              :wordmotion_extra ["\\([a-f]\\+[0-9]\\+\\([a-f]\\|[0-9]\\)*\\)\\+"
                                 "\\([0-9]\\+[a-f]\\+\\([0-9]\\|[a-f]\\)*\\)\\+"
                                 "\\([A-F]\\+[0-9]\\+\\([A-F]\\|[0-9]\\)*\\)\\+"
                                 "\\([0-9]\\+[A-F]\\+\\([0-9]\\|[A-F]\\)*\\)\\+"]
              :zig_fmt_autosave 0}]
    (each [name value (pairs vars)]
      (vim.api.nvim_set_var name value))))

(fn set-ui-options []
  (let [options {:cursorline  true
                 :cursorlineopt  "number"
                 :termguicolors  true
                 :showcmd  false
                 :laststatus  0
                 :ruler  true
                 :rulerformat  "%-14.(%l,%c   %o%)"
                 :guicursor  "a:block"
                 :mouse  ""
                 :shiftround  true
                 :shortmess  "filnxtToOFIc"
                 :number  true
                 :relativenumber  true
                 :lazyredraw  true
                 :isfname "@,48-57,/,.,-,_,+,,,#,$,%,~,=,@-@"}
        color-mod (require :fsouza.color)]
    (each [name value (pairs options)]
      (tset vim.o name value))
    (color-mod.enable)))

(fn set-global-options []
  (let [options {:completeopt  "menuone,noinsert,noselect"
                 :hidden  true
                 :hlsearch  false
                 :incsearch  true
                 :wildmenu  true
                 :wildmode  "list:longest"
                 :backup  false
                 :inccommand  "nosplit"
                 :jumpoptions  "stack"
                 :scrolloff  2
                 :autoindent  true
                 :smartindent  true
                 :swapfile  false
                 :undofile  true
                 :joinspaces  false
                 :synmaxcol  300
                 :showmatch true
                 :matchtime 2}]
    (each [name value (pairs options)]
      (tset vim.o name value))))

(fn set-folding []
  (vim.api.nvim_set_option :foldlevelstart 99)
  (vim.cmd "set foldmethod=indent"))

(fn set-global-mappings []
  (let [rl-bindings [{:lhs "<c-a>" :rhs "<home>" :opts {:noremap true}}
                     {:lhs "<c-e>" :rhs "<end>" :opts {:noremap true}}
                     {:lhs "<c-f>" :rhs "<right>" :opts {:noremap true}}
                     {:lhs "<c-b>" :rhs "<left>" :opts {:noremap true}}
                     {:lhs "<c-p>" :rhs "<up>" :opts {:noremap true}}
                     {:lhs "<c-n>" :rhs "<down>" :opts {:noremap true}}
                     {:lhs "<c-d>" :rhs "<del>" :opts {:noremap true}}
                     {:lhs "<m-p>" :rhs "<up>" :opts {:noremap true}}
                     {:lhs "<m-n>" :rhs "<down>" :opts {:noremap true}}
                     {:lhs "<m-b>" :rhs "<s-left>" :opts {:noremap true}}
                     {:lhs "<m-f>" :rhs "<s-right>" :opts {:noremap true}}
                     {:lhs "<m-d>" :rhs "<s-right><c-w>" :opts {:noremap true}}]
        rl-insert-mode-bindings [{:lhs "<c-f>" :rhs "<right>" :opts {:noremap true}}
                                 {:lhs "<c-b>" :rhs "<left>" :opts {:noremap true}}
                                 {:lhs "<c-d>" :rhs "<del>" :opts {:noremap true}}]
        mappings {:c rl-bindings :o rl-bindings :i rl-insert-mode-bindings}
        helpers (require :fsouza.lib.nvim-helpers)]
    (helpers.create-mappings mappings)))

(do
  (hererocks)
  (add-paqs-opt-to-path)
  (initial-mappings)
  (vim-schedule
    (set-global-options)
    (set-global-mappings))
  (set-ui-options)
  (set-folding)
  (set-neovim-global-vars)
  (if vim.env.BOOTSTRAP_PAQ
    (let [packed-mod (require :fsouza.packed)]
      (packed-mod.setup))
    (vim-schedule (require :fsouza.plugin))))
