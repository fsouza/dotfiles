(import-macros {: reload : mod-invoke} :helpers)

(fn download-packer [packer-dir cb]
  (let [packer-repo-dir (mod-invoke :fsouza.pl.path :join packer-dir :opt
                                    :packer.nvim)]
    (mod-invoke :fsouza.lib.cmd :run :git
                {:args [:clone
                        "https://github.com/wbthomason/packer.nvim.git"
                        packer-repo-dir]}
                #(if (= $1.exit-status 0)
                     (do
                       (vim.cmd.packadd {:args [:packer.nvim] :bang true})
                       (cb (require :packer)))
                     (error (string.format "failed to clone paq-nvim: %s"
                                           (vim.inspect $1)))))))

(fn with-packer [packer-dir cb]
  (let [(ok? packer) (pcall require :packer)]
    (if ok?
        (cb packer)
        (download-packer packer-dir cb))))

(let [path (require :fsouza.pl.path)
      package-root (path.join data-dir :site :pack)
      plugin-package :packer
      packer-dir (path.join package-root plugin-package)
      pkgs [{1 :wbthomason/packer.nvim :opt true :as :packer.nvim}
            {1 :chaoren/vim-wordmotion}
            {1 :godlygeek/tabular}
            {1 :justinmk/vim-dirvish}
            {1 :justinmk/vim-sneak}
            {1 :mattn/emmet-vim}
            {1 :michaeljsmith/vim-indent-object}
            {1 :tpope/vim-fugitive}
            {1 :tpope/vim-repeat}
            {1 :tpope/vim-rhubarb}
            {1 :tpope/vim-surround}
            {1 :nvim-treesitter/nvim-treesitter}
            {1 :nvim-treesitter/nvim-treesitter-refactor}
            {1 :nvim-treesitter/nvim-treesitter-textobjects
             :after :nvim-treesitter}
            {1 :nvim-treesitter/playground}
            {1 :numToStr/Comment.nvim}
            {1 :JoosepAlviste/nvim-ts-context-commentstring}
            {1 :fsouza/nvim-lsp-compl :as :nvim-lsp-compl :opt true}
            {1 :l3mon4d3/luasnip :as :luasnip :opt true}
            {1 :ibhagwan/fzf-lua :as :fzf-lua :opt true}
            {1 :norcalli/nvim-colorizer.lua :as :nvim-colorizer.lua :opt true}
            {1 :rhysd/git-messenger.vim :opt true}
            {1 :simrat39/symbols-outline.nvim
             :opt true
             :as :symbols-outline.nvim}
            {1 :vijaymarupudi/nvim-fzf :opt true}
            {1 :b0o/SchemaStore.nvim :as :SchemaStore.nvim :opt true}
            {1 :j-hui/fidget.nvim :as :fidget.nvim :opt true}
            {1 :nvim-lua/plenary.nvim :as :plenary.nvim :opt true}
            {1 :ziontee113/syntax-tree-surfer
             :as :syntax-tree-surfer
             :opt true}
            {1 :guns/vim-sexp}
            {1 :tpope/vim-sexp-mappings-for-regular-people}
            ; filetypes stuff
            ;
            ; Note: I used to use vim-polyglot, but it loads too much garbage and
            ; requires setting some global variables that I don't want to have
            ; to set, so whenever I want to add something new, I just look at
            ; what's used in vim-polyglot and bring it from there, unless I
            ; know a better alternative.
            {1 :fsouza/fennel.vim}
            {1 :HerringtonDarkholme/yats.vim}
            {1 :jakwings/vim-pony}
            {1 :ocaml/vim-ocaml}
            {1 :pangloss/vim-javascript}
            {1 :tbastos/vim-lua}
            {1 :Vimjas/vim-python-pep8-indent}
            {1 :ziglang/zig.vim}
            ;; themes, for demos/presentations.
            {1 :rose-pine/neovim}]]
  {: packer-dir
   : pkgs
   :setup #(with-packer packer-dir
                        (fn [packer]
                          (packer.startup {1 #(let [use $1]
                                                (each [_ pkg (ipairs pkgs)]
                                                  (use pkg)))
                                           :config {:package_root package-root
                                                    :plugin_package plugin-package
                                                    :disable_commands true
                                                    :autoremove true
                                                    :compile_on_sync false}})
                          (packer.sync)))
   :repack (fn []
             (let [packed (reload :fsouza.packed)]
               (packed.setup)))})
