(import-macros {: vim-schedule : if-nil} :fsouza-macros)

(local helpers (require "fsouza.lib.nvim-helpers"))

(fn parse-output [data]
  (collect [_ line (ipairs (vim.split data "\n"))]
    (let [parts (vim.split line "=")]
      (when (= (length parts) 2)
        (values (. parts 1) (. parts 2))))))

(fn get-vim-fenc [v]
  (match v
    "utf-8" (values v false)
    "latin1" (values v false)
    "utf-16be" (values v true)
    "utf-16le" (values v true)
    _ (values "utf-8" true)))

(fn handle-charset [vim-opts v]
  (let [(fenc bomb) (get-vim-fenc v)]
    (tset vim-opts :fileencoding fenc)
    (tset vim-opts :bomb bomb)))

(fn handle-eol [vim-opts v]
  (tset vim-opts :fileformat (match v
                               "crlf" "dos"
                               "cr" "mac"
                               _ "unix")))

(fn handle-indent-style [vim-opts v]
  (tset vim-opts :expandtab (or (= v "space") (= v "spaces"))))

(fn handle-insert-final-line [vim-opts v]
  (tset vim-opts :fixendofline (= v "true")))

(fn handle-indent-size [vim-opts v]
  (let [indent-size (tonumber v)]
    (tset vim-opts :shiftwidth indent-size)
    (tset vim-opts :softtabstop indent-size)))

(fn trim-whitespace []
  (let [view (vim.fn.winsaveview)]
    (pcall (partial vim.cmd "silent! keeppatterns %s/\\v\\s+$//"))
    (vim.fn.winrestview view)))

(fn handle-whitespaces [bufnr v]
  (let [commands []]
    (when (= v "true")
      (table.insert commands {:events ["BufWritePre"]
                              :targets [(string.format "<buffer=%d>" bufnr)]
                              :command (helpers.fn-cmd trim-whitespace)}))

    (when (vim.api.nvim_buf_is_valid bufnr)
      (helpers.augroup (.. "editorconfig_trim_trailing_whitespace_" bufnr) commands))))

(fn set-opts [bufnr opts]
  (let [vim-opts {:tabstop 8}]
    (each [k v (pairs opts)]
      (match k
        "charset" (handle-charset vim-opts v)
        "end_of_line" (handle-eol vim-opts v)
        "indent_style" (handle-indent-style vim-opts v)
        "insert_final_line" (handle-insert-final-line vim-opts v)
        "insert_final_newline" (handle-insert-final-line vim-opts v)
        "indent_size" (handle-indent-size vim-opts v)
        "trim_trailing_whitespace" (vim-schedule (handle-whitespaces bufnr v))))

    (vim-schedule
      (when (and (vim.api.nvim_buf_is_valid bufnr) (vim.api.nvim_buf_get_option bufnr "modifiable"))
        (each [option-name value (pairs vim-opts)]
          (vim.api.nvim_buf_set_option bufnr option-name value))))))

(fn set-config [bufnr]
  (let [bufnr (if-nil bufnr (vim.api.nvim_get_current_buf))
        filename (vim.api.nvim_buf_get_name bufnr)]
    (when (and (?. vim :bo bufnr :modifiable) (not (?. vim :bo bufnr :readonly)) (not= filename ""))
      (let [filename (if (vim.startswith filename "/")
                       filename
                       (let [pl-path (require "pl.path")]
                         (pl-path.join (vim.fn.getcwd) filename)))
            cmd (require "fsouza.lib.cmd")]
        (cmd.run
          "editorconfig"
          {:args [filename]}
          nil
          (fn [result]
            (if (= result.exit-status 0)
              (set-opts bufnr (parse-output result.stdout))
              (vim.notify (string.format "failed to run editorconfig: %s" (vim.inspect result))))))))))

(local set-config-cmd (helpers.fn-cmd set-config))

(fn set-enabled [v]
  (let [commands []]
    (when v
      (table.insert commands {:events ["BufNewFile" "BufReadPost" "BufFilePost"]
                              :targets ["*"]
                              :command set-config-cmd})
      (vim-schedule
        (each [_ bufnr (ipairs (vim.api.nvim_list_bufs))]
          (set-config bufnr))))
    (helpers.augroup "editorconfig" commands)))

{:enable (partial set-enabled true)
 :disable (partial set-enabled false)}
