(import-macros {: if-nil : abuf} :helpers)

(local helpers (require :fsouza.lib.nvim-helpers))

(local tablex (require :fsouza.tablex))

(fn lang-to-ft [lang]
  (let [parsers (require :nvim-treesitter.parsers)
        obj (. parsers.list lang)]
    (vim.tbl_flatten [(if-nil obj.filetype lang)] (if-nil obj.used_by []))))

(fn get-file-types []
  (let [parsers-mod (require :nvim-treesitter.parsers)
        wanted-parsers (parsers-mod.maintained_parsers)]
    (tablex.flat-map lang-to-ft wanted-parsers)))

(local load-nvim-gps (helpers.once (fn []
                                     (vim.cmd "packadd nvim-gps")
                                     (let [nvim-gps (require :nvim-gps)]
                                       (nvim-gps.setup {:icons {:class-name "￠ "
                                                                :function-name "ƒ "
                                                                :method-name "ƒ "}})
                                       nvim-gps))))

(fn create-mappings [bufnr]
  (let [bufnr (if-nil bufnr (if-nil (abuf) vim.api.nvim_get_current_buf))]
    (vim.keymap.set :n :<leader>w
                    #(let [{: get_location} (load-nvim-gps)
                           location (get_location)]
                       (vim.notify location))
                    {:buffer bufnr})))

(fn set-folding []
  (helpers.augroup :fsouza__folding_config
                   [{:events [:FileType]
                     :targets (get-file-types)
                     :command "setlocal foldmethod=expr foldexpr=nvim_treesitter#foldexpr()"}]))

(fn mappings []
  (helpers.augroup :fsouza__ts_mappings
                   [{:events [:FileType]
                     :targets (get-file-types)
                     :command (helpers.fn-cmd create-mappings)}]))

(do
  (let [configs (require :nvim-treesitter.configs)]
    (configs.setup {:highlight {:enable true}
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
                    :ensure_installed :maintained}))
  (set-folding)
  (mappings))
