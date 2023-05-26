(import-macros {: mod-invoke} :helpers)

(local ignore-install [:phpdoc])

(fn lang-to-ft [lang]
  (if (vim.tbl_contains ignore-install lang) []
      (let [parsers (require :nvim-treesitter.parsers)
            obj (. parsers.list lang)]
        (vim.tbl_flatten [(or obj.filetype lang)] (or obj.used_by [])))))

(fn get-file-types []
  (let [parsers-mod (require :nvim-treesitter.parsers)
        wanted-parsers (parsers-mod.available_parsers)]
    (mod-invoke :fsouza.pl.tablex :flat-map lang-to-ft wanted-parsers)))

(fn setup-keymaps [buffer]
  (let [{: keymap-repeat} (require :fsouza.lib.nvim-helpers)]
    (keymap-repeat :>e #(mod-invoke :tree-climber :swap_next)
                   {: buffer :silent true})
    (keymap-repeat :<e #(mod-invoke :tree-climber :swap_prev)
                   {: buffer :silent true})
    (keymap-repeat :>f #(mod-invoke :syntax-tree-surfer :move :n false)
                   {: buffer :silent true})
    (keymap-repeat :<f #(mod-invoke :syntax-tree-surfer :move :n true)
                   {: buffer :silent true})
    (keymap-repeat :vv #(mod-invoke :syntax-tree-surfer :select_current_node)
                   {: buffer :silent true})
    (vim.keymap.set :x :J #(mod-invoke :syntax-tree-surfer :surf :next :visual)
                    {: buffer :silent true})
    (vim.keymap.set :x :K #(mod-invoke :syntax-tree-surfer :surf :prev :visual)
                    {: buffer :silent true})
    (vim.keymap.set :x :<tab>
                    #(mod-invoke :syntax-tree-surfer :surf :parent :visual)
                    {: buffer :silent true})
    (vim.keymap.set :x :<s-tab>
                    #(mod-invoke :syntax-tree-surfer :surf :child :visual)
                    {: buffer :silent true})
    (vim.keymap.set :x :<leader>a
                    #(mod-invoke :syntax-tree-surfer :surf :next :visual true)
                    {: buffer :silent true})
    (vim.keymap.set :x :<leader>A
                    #(mod-invoke :syntax-tree-surfer :surf :prev :visual true)
                    {: buffer :silent true})
    (vim.keymap.set :n :<c-k>
                    #(do
                       (vim.cmd.normal "m'")
                       (mod-invoke :tree-climber :goto_parent))
                    {: buffer :silent true})))

(fn on-FileType [{: buf}]
  (setup-keymaps buf))

(fn setup-autocmds []
  (let [targets (get-file-types)]
    (mod-invoke :fsouza.lib.nvim-helpers :augroup :fsouza__treesitter_autocmd
                [{:events [:FileType] : targets :callback on-FileType}])))

(do
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
                             :swap {:enable true
                                    :swap_next {:<leader>a "@parameter.inner"}
                                    :swap_previous {:<leader>A "@parameter.inner"}}}
               :context_commentstring {:enable true :enable_autocmd false}
               :refactor {:navigation {:enable [:graphql :proto :thrift]
                                       :keymaps {:goto_definition :gd}}}
               :ensure_installed []
               :auto_install true
               :ignore_install ignore-install})
  (setup-autocmds))
