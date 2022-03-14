(import-macros {: vim-schedule} :helpers)

(global config-dir (vim.fn.expand "~/.dotfiles/nvim"))

(macro hererocks []
  `(let [lua-version# (string.gsub _G._VERSION "Lua " "")
         cache-dir# (vim.fn.stdpath :cache)
         hererocks-path# (.. cache-dir# :/hr)
         share-path# (.. hererocks-path# :/share/lua/ lua-version#)
         lib-path# (.. hererocks-path# :/lib/lua/ lua-version#)]
     (tset package :path (table.concat [(.. share-path# :/?.lua)
                                        (.. share-path# :/?/init.lua)
                                        package.path]
                                       ";"))
     (tset package :cpath (table.concat [(.. lib-path# :/?.so) package.cpath]
                                        ";"))))

(macro add-paqs-opt-to-path []
  `(let [path# (require :pl.path)
         packed# (require :fsouza.packed)
         opt-dir# (path#.join packed#.paq-dir :opt)]
     (each [_# paq# (ipairs packed#.paqs)]
       (when (and paq#.opt paq#.as)
         (let [paq-dir# (path#.join opt-dir# paq#.as)]
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
  (let [vars {:netrw_home `(vim.fn.stdpath :data)
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
              :did_load_filetypes 0
              :do_filetype_lua 1
              :loaded_python3_provider 0
              :loaded_ruby_provider 0
              :loaded_perl_provider 0
              :loaded_node_provider 0}]
    (icollect [name value (pairs vars)]
      `(tset vim.g ,name ,value))))

(macro set-ui-options []
  (let [options {:cursorline true
                 :cursorlineopt :number
                 :showcmd false
                 :laststatus 0
                 :ruler true
                 :rulerformat "%-14.(%l,%c   %o%)"
                 :guicursor "a:block"
                 :mouse ""
                 :shiftround true
                 :shortmess :filnxtToOFIc
                 :lazyredraw true
                 :isfname "@,48-57,/,.,-,_,+,,,#,$,%,~,=,@-@"}]
    (list (sym :do) (icollect [name value (pairs options)]
                      `(tset vim.o ,name ,value))
          `(vim.cmd "color none"))))

(macro set-global-options []
  (let [options {:completeopt "menuone,noinsert,noselect"
                 :hidden true
                 :hlsearch false
                 :incsearch true
                 :wildmenu true
                 :wildmode "list:longest"
                 :backup false
                 :inccommand :nosplit
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
      `(tset vim.o ,name ,value))))

(macro set-folding []
  `(do
     (vim.api.nvim_set_option :foldlevelstart 99)
     (vim.cmd "set foldmethod=indent")))

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
                                 {:lhs :<c-b> :rhs :<left>}
                                 {:lhs :<c-d> :rhs :<del>}]]
    (list (sym :do)
          (icollect [_ {: lhs : rhs} (ipairs rl-bindings)]
            `(vim.keymap.set [:c :o] ,lhs ,rhs {:remap false}))
          (icollect [_ {: lhs : rhs} (ipairs rl-insert-mode-bindings)]
            `(vim.keymap.set :i ,lhs ,rhs {:remap false})))))

(do
  (hererocks)
  (add-paqs-opt-to-path)
  (initial-mappings)
  (vim-schedule (set-global-options) (set-global-mappings))
  (set-ui-options)
  (set-folding)
  (set-neovim-global-vars)
  (if vim.env.BOOTSTRAP_PAQ
      (let [packed (require :fsouza.packed)]
        (packed.setup))
      (vim-schedule (require :fsouza.plugin))))
