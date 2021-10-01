(local helpers (require "fsouza.lib.nvim-helpers"))

(local tablex (require "fsouza.tablex"))

(local wanted-parsers ["bash" "c" "cpp" "css" "go" "html" "javascript" "json"
                       "lua" "ocaml" "ocaml_interface" "ocamllex" "python" "query"
                       "regex" "toml" "tsx" "typescript"])

(fn lang-to-ft [lang]
  (let [parsers (require "nvim-treesitter.parsers")
        obj (. parsers.list lang)]
    (vim.tbl_flatten [(vim.F.if_nil obj.filetype lang)] (vim.F.if_nil obj.used_by []))))

(fn get-file-types []
  (tablex.flat-map lang-to-ft wanted-parsers))

(local setup-gps (helpers.once
                   (fn []
                     (vim.cmd "packadd nvim-gps")
                     (let [nvim-gps (require "nvim-gps")]
                       (nvim-gps.setup {:icons {:class-name "￠ "
                                                :function-name "ƒ "
                                                :method-name "ƒ "} })))))

(local gps-cmd (helpers.fn-map (fn []
                                 (setup-gps)
                                 (let [nvim-gps (require "nvim-gps")
                                       location (nvim-gps.get_location)]
                                   (vim.notify location)))))

(fn create-mappings [bufnr]
  (let [bufnr (helpers.if-nil
                bufnr
                (fn []
                  (helpers.if-nil
                    (vim.fn.expand "<abuf>")
                    vim.api.nvim_get_current_buf)))]

    (helpers.create-mappings {:n [{:lhs "<leader>w"
                                   :rhs gps-cmd
                                   :opts {:noremap true}}]} bufnr)))

(fn set-folding []
  (helpers.augroup
    "fsouza__folding_config"
    [{:events ["FileType"]
      :targets (get-file-types)
      :command "setlocal foldmethod=expr foldexpr=nvim_treesitter#foldexpr()"}]))

(fn mappings []
  (helpers.augroup
    "fsouza__ts_mappings"
    [{:events ["FileType"]
      :targets (get-file-types)
      :command (helpers.fn-cmd create-mappings)}]))

(do
  (let [configs (require "nvim-treesitter.configs")]
    (configs.setup {:highlight {:enable false}
                    :playground {:enable true
                                 :updatetime 10}
                    :textobjects {:select {:enable true
                                           :keymaps {:af "@function.outer"
                                                     :if "@function.inner"
                                                     :al "@block.outer"
                                                     :il "@block.inner"
                                                     :ac "@class.outer"
                                                     :ic "@class.inner"}}
                                  :move {:enable true
                                         :set_jumps true
                                         :goto_next_start {:<leader>m "@function.outer"}
                                         :goto_previous_start {:<leaer>M "@function.outer"}}
                                  :swap {:enable true
                                         :swap_next {:<leader>a "@parameter.inner"}
                                         :swap_previos {:<leader>A "@parameter.inner"}}}
                    :ensure_installed wanted-parsers}))
  (set-folding)
  (mappings))
