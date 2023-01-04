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

(fn setup-packages []
  (global dotfiles-dir vim.env.FSOUZA_DOTFILES_DIR)
  (global config-dir (.. dotfiles-dir :/nvim))
  (global cache-dir (vim.fn.stdpath :cache))
  (global data-dir (vim.fn.stdpath :data))
  (hererocks)
  (add-pkgs-opt-to-path))

{: setup-packages}
