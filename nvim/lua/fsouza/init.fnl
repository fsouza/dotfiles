(import-macros {: mod-invoke} :helpers)

(macro hererocks []
  `(let [lua-version# (string.gsub _G._VERSION "Lua " "")
         hererocks-path# (.. cache-dir :/hr)
         share-path# (.. hererocks-path# :/share/lua/ lua-version#)
         lib-path# (.. hererocks-path# :/lib/lua/ lua-version#)]
     (tset package :path (table.concat [(.. share-path# :/?.lua)
                                        (.. share-path# :/?/init.lua)
                                        package.path]
                                       ";"))
     (tset package :cpath (table.concat [(.. lib-path# :/?.so) package.cpath]
                                        ";"))))

(macro add-pkgs-opt-to-path []
  `(let [path# (require :fsouza.pl.path)
         packed# (require :fsouza.packed)
         opt-dir# (path#.join packed#.packer-dir :opt)]
     (each [_# pkg# (ipairs packed#.pkgs)]
       (when (and pkg#.opt pkg#.as)
         (let [paq-dir# (path#.join opt-dir# pkg#.as)]
           (tset package :path
                 (table.concat [package.path
                                (path#.join paq-dir# :lua :?.lua)
                                (path#.join paq-dir# :lua "?" :?.lua)
                                (path#.join paq-dir# :lua "?" :init.lua)]
                               ";")))))))

(macro initial-mappings []
  `(do
     (vim.keymap.set :n :Q "")
     (vim.keymap.set :n :<Space> "")
     (tset vim.g :mapleader " ")))

(macro set-neovim-global-vars []
  (let [vars {:netrw_home `data-dir
              :netrw_banner 0
              :netrw_liststyle 3
              :surround_no_insert_mappings true
              :user_emmet_mode :i
              :user_emmet_leader_key :<C-x>
              :wordmotion_extra ["\\([a-f]\\+[0-9]\\+\\([a-f]\\|[0-9]\\)*\\)\\+"
                                 "\\([0-9]\\+[a-f]\\+\\([0-9]\\|[a-f]\\)*\\)\\+"
                                 "\\([A-F]\\+[0-9]\\+\\([A-F]\\|[0-9]\\)*\\)\\+"
                                 "\\([0-9]\\+[A-F]\\+\\([0-9]\\|[A-F]\\)*\\)\\+"]
              :wordmotion_uppercase_spaces ["(" ")" "[" "]" "{" "}"]
              :zig_fmt_autosave 0
              :sexp_filetypes "clojure,dune,fennel,scheme,lisp,timl"
              :sexp_enable_insert_mode_mappings 0
              :sexp_no_word_maps 1
              :loaded_python3_provider 0
              :loaded_ruby_provider 0
              :loaded_perl_provider 0
              :loaded_node_provider 0
              :loaded_remote_plugins 1
              :loaded_tarPlugin 1
              :loaded_2html_plugin 1
              :loaded_tutor_mode_plugin 1
              :loaded_zipPlugin 1
              :no_plugin_maps 1}]
    (icollect [name value (pairs vars)]
      `(tset vim.g ,name ,value))))

(macro set-ui-options []
  (let [options {:cursorline true
                 :cursorlineopt :number
                 :showcmd false
                 :laststatus 0
                 :showmode true
                 :ruler true
                 :rulerformat "%25(%=%{v:lua.require('fsouza.lib.notif')['get-notification']()}%{v:lua.require('fsouza.lsp.diagnostics').ruler()}   %l,%c%)"
                 :guicursor "a:block"
                 :mouse ""
                 :shiftround true
                 :shortmess :filnxtToOFIc
                 :number true
                 :relativenumber true
                 :isfname "@,48-57,/,.,-,_,+,,,#,$,%,~,=,@-@"}]
    (list (sym :do)
          (icollect [name value (pairs options)]
            `(vim.api.nvim_set_option_value ,name ,value {}))
          `(vim.cmd.color :none))))

(macro set-global-options []
  (let [options {:completeopt "menuone,noinsert,noselect"
                 :hidden true
                 :hlsearch false
                 :incsearch true
                 :wildmenu true
                 :wildmode "list:longest"
                 :backup false
                 :inccommand :split
                 :jumpoptions :stack
                 :scrolloff 2
                 :autoindent true
                 :smartindent true
                 :swapfile false
                 :undofile true
                 :joinspaces false
                 :synmaxcol 300
                 :showmatch true
                 :matchtime 1}]
    (icollect [name value (pairs options)]
      `(vim.api.nvim_set_option_value ,name ,value {}))))

(macro set-global-mappings []
  (let [rl-bindings [{:lhs :<c-a> :rhs :<home>}
                     {:lhs :<c-e> :rhs :<end>}
                     {:lhs :<c-f> :rhs :<right>}
                     {:lhs :<c-b> :rhs :<left>}
                     {:lhs :<c-p> :rhs :<up>}
                     {:lhs :<c-n> :rhs :<down>}
                     {:lhs :<c-d> :rhs :<del>}
                     {:lhs :<m-p> :rhs :<up>}
                     {:lhs :<m-n> :rhs :<down>}
                     {:lhs :<m-b> :rhs :<s-left>}
                     {:lhs :<m-f> :rhs :<s-right>}
                     {:lhs :<m-d> :rhs :<s-right><c-w>}]
        rl-insert-mode-bindings [{:lhs :<c-f> :rhs :<right>}
                                 {:lhs :<c-b> :rhs :<left>}]
        exprs [`(vim.keymap.set [:x :v] "#"
                                "\"my?\\V<C-R>=escape(getreg(\"m\"), \"?\")<CR><CR>"
                                {:remap false})
               `(vim.keymap.set [:x :v] "*"
                                "\"my/\\V<C-R>=escape(getreg(\"m\"), \"/\")<CR><CR>"
                                {:remap false})
               `(vim.keymap.set [:x :v] :p "\"_dP" {:remap false})]]
    (each [_ {: lhs : rhs} (ipairs rl-bindings)]
      (table.insert exprs `(vim.keymap.set [:c :o] ,lhs ,rhs {:remap false})))
    (each [_ {: lhs : rhs} (ipairs rl-insert-mode-bindings)]
      (table.insert exprs `(vim.keymap.set :i ,lhs ,rhs {:remap false})))
    exprs))

(macro override-builtin-functions []
  `(do
     (tset vim.ui :select
           (fn [...]
             (mod-invoke :fsouza.lib.popup-picker :ui-select ...)))
     (let [orig-uri-to-fname# vim.uri_to_fname]
       (fn uri-to-fname# [uri#]
         (-> uri#
             (orig-uri-to-fname#)
             (vim.fn.fnamemodify ":.")))

       (tset vim :uri_to_fname uri-to-fname#)
       (tset vim :uri_to_bufnr
             (fn [uri#]
               (-> uri#
                   (uri-to-fname#)
                   (vim.fn.bufadd)))))))

(if vim.env.FSOUZA_DOTFILES_DIR
    (do
      (global dotfiles-dir vim.env.FSOUZA_DOTFILES_DIR)
      (global config-dir (.. dotfiles-dir :/nvim))
      (global cache-dir (vim.fn.stdpath :cache))
      (global data-dir (vim.fn.stdpath :data))
      (hererocks)
      (add-pkgs-opt-to-path)
      (initial-mappings)
      (set-global-options)
      (set-global-mappings)
      (override-builtin-functions)
      (set-ui-options)
      (set-neovim-global-vars)
      (if vim.env.BOOTSTRAP_PACKER
          (mod-invoke :fsouza.packed :setup)
          (require :fsouza.plugin)))
    (error "missing FSOUZA_DOTFILES_DIR\n"))
