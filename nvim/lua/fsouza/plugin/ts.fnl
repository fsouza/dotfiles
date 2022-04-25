(import-macros {: if-nil : abuf : mod-invoke} :helpers)

(fn lang-to-ft [lang]
  (let [parsers (require :nvim-treesitter.parsers)
        obj (. parsers.list lang)]
    (vim.tbl_flatten [(if-nil obj.filetype lang)] (if-nil obj.used_by []))))

(fn get-file-types []
  (let [parsers-mod (require :nvim-treesitter.parsers)
        wanted-parsers (parsers-mod.available_parsers)]
    (mod-invoke :fsouza.pl.tablex :flat-map lang-to-ft wanted-parsers)))

(fn setup-keymaps [buffer]
  (vim.keymap.set :n :>e #(mod-invoke :syntax-tree-surfer :surf :next :normal
                                      true)
                  {: buffer :silent true})
  (vim.keymap.set :n :<e #(mod-invoke :syntax-tree-surfer :surf :prev :normal
                                      true)
                  {: buffer :silent true})
  (vim.keymap.set :n :>f #(mod-invoke :syntax-tree-surfer :move :n false)
                  {: buffer :silent true})
  (vim.keymap.set :n :<f #(mod-invoke :syntax-tree-surfer :move :n true)
                  {: buffer :silent true})
  (vim.keymap.set :n :vv #(mod-invoke :syntax-tree-surfer :select_current_node)
                  {: buffer :silent true})
  (vim.keymap.set :x :J #(mod-invoke :syntax-tree-surfer :surf :next :visual)
                  {: buffer :silent true})
  (vim.keymap.set :x :K #(mod-invoke :syntax-tree-surfer :surf :prev :visual)
                  {: buffer :silent true})
  (vim.keymap.set :x :<tab> #(mod-invoke :syntax-tree-surfer :surf :parent
                                         :visual)
                  {: buffer :silent true})
  (vim.keymap.set :x :<s-tab>
                  #(mod-invoke :syntax-tree-surfer :surf :child :visual)
                  {: buffer :silent true})
  (vim.keymap.set :x :<leader>a
                  #(mod-invoke :syntax-tree-surfer :surf :next :visual true)
                  {: buffer :silent true})
  (vim.keymap.set :x :<leader>A
                  #(mod-invoke :syntax-tree-surfer :surf :prev :visual true)
                  {: buffer :silent true}))

(fn on-FileType []
  (let [bufnr (abuf)]
    (when bufnr
      (setup-keymaps bufnr)
      (vim.api.nvim_buf_call bufnr
                             #(do
                                (vim.api.nvim_set_option_value :foldmethod
                                                               :expr
                                                               {:scope :local})
                                (vim.api.nvim_set_option_value :foldexpr
                                                               "nvim_treesitter#foldexpr()"
                                                               {:scope :local}))))))

(fn setup-autocmds []
  (let [targets (get-file-types)]
    (mod-invoke :fsouza.lib.nvim-helpers :augroup :fsouza__treesitter_autocmd
                [{:events [:FileType] : targets :callback on-FileType}])))

(fn setup []
  (mod-invoke :nvim-treesitter.configs :setup
              {:highlight {:enable true}
               :playground {:enable true :updatetime 10}
               :textobjects {:select {:enable true
                                      :lookahead true
                                      :keymaps {:af "@function.outer"
                                                :if "@function.inner"
                                                :al "@block.outer"
                                                :il "@block.inner"
                                                :ac "@class.outer"
                                                :ic "@class.inner"
                                                "a," "@parameter.outer"
                                                "i," "@parameter.inner"}}
                             :move {:enable true
                                    :set_jumps true
                                    :goto_next_start {:<leader>m "@function.outer"}
                                    :goto_previous_start {:<leader>M "@function.outer"}}
                             :swap {:enable true
                                    :swap_next {:<leader>a "@parameter.inner"}
                                    :swap_previous {:<leader>A "@parameter.inner"}}}
               :context_commentstring {:enable true :enable_autocmd false}
               :ensure_installed :all
               :ignore_install [:phpdoc]})
  (setup-autocmds))

{: setup}
