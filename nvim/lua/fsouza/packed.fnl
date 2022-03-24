(import-macros {: reload : mod-invoke} :helpers)

(fn download-paq [paq-dir cb]
  (let [path (require :pl.path)
        paq-repo-dir (path.join paq-dir :opt :paq-nvim)]
    (mod-invoke :fsouza.lib.cmd :run :git
                {:args [:clone
                        :--depth=1
                        "https://github.com/savq/paq-nvim.git"
                        paq-repo-dir]} nil
                #(if (= $1.exit-status 0)
                     (do
                       (vim.cmd "packadd! paq-nvim")
                       (cb (require :paq)))
                     (error (string.format "failed to clone paq-nvim: %s"
                                           (vim.inspect $1)))))))

(fn with-paq [paq-dir cb]
  (let [(ok? paq) (pcall require :paq)]
    (if ok?
        (cb paq)
        (download-paq paq-dir cb))))

(let [path (require :pl.path)
      paq-dir (path.join (vim.fn.stdpath :data) :site :pack :paqs)
      paqs [{1 :savq/paq-nvim :opt true :as :paq-nvim}
            [:chaoren/vim-wordmotion]
            [:godlygeek/tabular]
            [:guns/vim-sexp]
            [:justinmk/vim-dirvish]
            [:justinmk/vim-sneak]
            [:mattn/emmet-vim]
            [:michaeljsmith/vim-indent-object]
            [:tpope/vim-fugitive]
            [:tpope/vim-repeat]
            [:tpope/vim-rhubarb]
            [:tpope/vim-sexp-mappings-for-regular-people]
            [:tpope/vim-surround]
            {1 :nvim-treesitter/nvim-treesitter
             :run (partial vim.cmd :TSUpdate)}
            [:nvim-treesitter/nvim-treesitter-textobjects]
            [:nvim-treesitter/nvim-treesitter-refactor]
            [:nvim-treesitter/playground]
            [:SmiteshP/nvim-gps]
            [:JoosepAlviste/nvim-ts-context-commentstring]
            {1 :fsouza/nvim-lsp-compl :as :nvim-lsp-compl :opt true}
            {1 :l3mon4d3/luasnip :as :luasnip :opt true}
            {1 :ibhagwan/fzf-lua :as :fzf-lua :opt true}
            {1 :neovim/nvim-lspconfig :as :nvim-lspconfig :opt true}
            {1 :norcalli/nvim-colorizer.lua :as :nvim-colorizer.lua :opt true}
            {1 :rhysd/git-messenger.vim :opt true}
            {1 :simrat39/symbols-outline.nvim
             :opt true
             :as :symbols-outline.nvim}
            {1 :vijaymarupudi/nvim-fzf :opt true}
            {1 :numToStr/Comment.nvim :as :Comment.nvim :opt true}
            {1 :b0o/SchemaStore.nvim :as :SchemaStore.nvim :opt true}
            {1 :feline-nvim/feline.nvim
             :as :feline.nvim
             :opt true
             :branch :develop}
            ; filetypes stuff
            ;
            ; Note: I used to use vim-polyglot, but it loads too much garbage and
            ; requires setting some global variables that I don't want to have to set
            ; :)
            [:clojure-vim/clojure.vim]
            [:fsouza/fennel.vim]
            [:HerringtonDarkholme/yats.vim]
            [:jakwings/vim-pony]
            [:keith/swift.vim]
            [:ocaml/vim-ocaml]
            [:pangloss/vim-javascript]
            [:tbastos/vim-lua]
            [:Vimjas/vim-python-pep8-indent]
            [:ziglang/zig.vim]
            [:shaunsingh/solarized.nvim]]]
  {: paq-dir
   : paqs
   :setup #(with-paq paq-dir (fn [paq]
                               (paq:setup {:paq_dir paq-dir})
                               (paq paqs)
                               (paq:sync)))
   :repack (fn []
             (let [packed (reload :fsouza.packed)]
               (packed.setup)))})
