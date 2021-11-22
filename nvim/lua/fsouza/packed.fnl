(local path (require :pl.path))

(fn download-paq [mod cb]
  (let [paq-repo-dir (path.join mod.paq-dir "opt" "paq-nvim")
        cmd (require :fsouza.lib.cmd)]

    (cmd.run
      "git"
      {:args ["clone" "--depth=1" "https://github.com/savq/paq-nvim.git" paq-repo-dir]}
      nil
      (fn [result]
        (if (= result.exit-status 0)
          (do
            (vim.cmd "packadd! paq-nvim")
            (cb (require :paq)))
          (error (string.format "failed to clone paq-nvim: %s" (vim.inspect result))))))))

(fn with-paq [mod cb]
  (let [(ok? paq) (pcall require :paq)]
    (if ok?
      (cb paq)
      (download-paq mod cb))))

(let [paq-dir (path.join (vim.fn.stdpath "data") "site" "pack" "paqs")
      mod {:paq-dir paq-dir
           :paqs [{1 "savq/paq-nvim" :opt true :as "paq-nvim"}
                  ["chaoren/vim-wordmotion"]
                  ["godlygeek/tabular"]
                  ["guns/vim-sexp"]
                  ["justinmk/vim-dirvish"]
                  ["justinmk/vim-sneak"]
                  ["mattn/emmet-vim"]
                  ["michaeljsmith/vim-indent-object"]
                  ["tpope/vim-commentary"]
                  ["tpope/vim-fugitive"]
                  ["tpope/vim-repeat"]
                  ["tpope/vim-rhubarb"]
                  ["tpope/vim-sexp-mappings-for-regular-people"]
                  ["tpope/vim-surround"]

                  ; treesitter
                  {1 "nvim-treesitter/nvim-treesitter" :run (partial vim.cmd "TSUpdate")}
                  ["nvim-treesitter/nvim-treesitter-textobjects"]
                  ["nvim-treesitter/playground"]
                  {1 "SmiteshP/nvim-gps" :opt true}

                  ; completion stuff
                  {1 "fsouza/nvim-lsp-compl" :as "nvim-lsp-compl" :opt true}
                  {1 "l3mon4d3/luasnip" :as "luasnip" :opt true}

                  ; misc opt stuff
                  {1 "ibhagwan/fzf-lua" :as "fzf-lua" :opt true}
                  {1 "neovim/nvim-lspconfig" :as "nvim-lspconfig" :opt true}
                  {1 "norcalli/nvim-colorizer.lua" :as "nvim-colorizer.lua" :opt true}
                  {1 "simrat39/symbols-outline.nvim" :opt true :as "symbols-outline.nvim"}
                  {1 "rhysd/git-messenger.vim" :opt true}
                  {1 "vijaymarupudi/nvim-fzf" :opt true}

                  ; filetypes stuff
                  ;
                  ; Note: I used to use vim-polyglot, but it loads too much garbage and
                  ; requires setting some global variables that I don't want to have to set
                  ; :)
                  ["clojure-vim/clojure.vim"]
                  ["fsouza/fennel.vim"]
                  ["HerringtonDarkholme/yats.vim"]
                  ["keith/swift.vim"]
                  ["ocaml/vim-ocaml"]
                  ["pangloss/vim-javascript"]
                  ["tbastos/vim-lua"]
                  ["Vimjas/vim-python-pep8-indent"]
                  ["ziglang/zig.vim"]

                  ; colorschemes
                  ["ishan9299/modus-theme-vim"]
                  ["ldelossa/vimdark"]
                  ["Th3Whit3Wolf/one-nvim"]]
           :repack (fn []
                     (tset package.loaded "fsouza.packed" nil)
                     (let [packed (require :fsouza.packed)]
                       (packed.setup)))}]
  (tset mod :setup (partial with-paq mod (fn [paq]
                                           (paq:setup {:paq_dir paq-dir})
                                           (paq mod.paqs)
                                           (paq:sync))))

mod)
