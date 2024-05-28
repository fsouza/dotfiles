(local ignore-install [:phpdoc])

(fn lang-to-ft [lang]
  (if (vim.tbl_contains ignore-install lang) []
      (let [parsers (require :nvim-treesitter.parsers)
            obj (. parsers.list lang)]
        [(or obj.filetype lang) (or obj.used_by [])])))

(fn get-file-types []
  (let [nvim-treesitter-parsers (require :nvim-treesitter.parsers)]
    (-> (nvim-treesitter-parsers.available_parsers)
        (vim.iter)
        (: :map lang-to-ft)
        (: :flatten math.huge)
        (: :totable))))

(let [configs (require :nvim-treesitter.configs)]
  (configs.setup {:highlight {:enable true
                              :disable #(and (= $1 :json)
                                             (= (vim.api.nvim_buf_line_count $2)
                                                1))}
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
                  :ensure_installed []
                  :auto_install true
                  :ignore_install ignore-install}))
