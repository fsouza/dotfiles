(import-macros {: if-nil : abuf : mod-invoke} :helpers)

(fn lang-to-ft [lang]
  (let [parsers (require :nvim-treesitter.parsers)
        obj (. parsers.list lang)]
    (vim.tbl_flatten [(if-nil obj.filetype lang)] (if-nil obj.used_by []))))

(fn get-file-types []
  (let [parsers-mod (require :nvim-treesitter.parsers)
        wanted-parsers (parsers-mod.maintained_parsers)]
    (mod-invoke :fsouza.tablex :flat-map lang-to-ft wanted-parsers)))

(fn set-folding []
  (mod-invoke :fsouza.lib.nvim-helpers :augroup :fsouza__folding_config
              [{:events [:FileType]
                :targets (get-file-types)
                :command "setlocal foldmethod=expr foldexpr=nvim_treesitter#foldexpr()"}]))

(do
  (mod-invoke :nvim-treesitter.configs :setup
              {:highlight {:enable true}
               :incremental_selection {:enable true
                                       :keymaps {:init_selection :gnn
                                                 :node_incremental :<tab>
                                                 :node_decremental :<s-tab>}}
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
                                    :swap_previos {:<leader>A "@parameter.inner"}}}
               :context_commentstring {:enable true :enable_autocmd false}
               :refactor {:navigation {:enable true
                                       :keymaps {:goto_definition :gd}}}
               :ensure_installed :maintained})
  (set-folding)
  (mod-invoke :nvim-gps :setup {:disable_icons true}))
