(import-macros {: mod-invoke} :helpers)

(fn parse-output [data]
  (collect [_ line (ipairs (vim.split data "\n"))]
    (let [parts (vim.split line "=")]
      (when (= (length parts) 2)
        (values (. parts 1) (. parts 2))))))

(fn get-vim-fenc [v]
  (match v
    :utf-8 (values v false)
    :latin1 (values v false)
    :utf-16be (values v true)
    :utf-16le (values v true)
    _ (values :utf-8 true)))

(fn handle-charset [vim-opts v]
  (let [(fenc bomb) (get-vim-fenc v)]
    (tset vim-opts :fileencoding fenc)
    (tset vim-opts :bomb bomb)))

(fn handle-eol [vim-opts v]
  (tset vim-opts :fileformat (match v
                               :crlf :dos
                               :cr :mac
                               _ :unix)))

(fn handle-indent-style [vim-opts v]
  (tset vim-opts :expandtab (= v :space)))

(fn handle-insert-final-line [vim-opts v]
  (tset vim-opts :fixendofline (= v :true))
  (tset vim-opts :endofline (= v :true)))

(fn handle-indent-size [vim-opts v opts]
  (let [indent-size (if (= opts.indent_style :space) (tonumber v) 0)]
    (tset vim-opts :shiftwidth indent-size)
    (tset vim-opts :softtabstop indent-size)))

(fn trim-whitespace [{: buf}]
  (vim.api.nvim_buf_call buf
                         #(let [cursor (vim.api.nvim_win_get_cursor 0)]
                            (pcall #(vim.cmd.substitute {:args ["/\\v\\s+$//"]
                                                         :range [1
                                                                 (vim.api.nvim_buf_line_count 0)]
                                                         :mods {:silent true
                                                                :keeppatterns true}}))
                            (vim.api.nvim_win_set_cursor 0 cursor))))

(fn handle-whitespaces [bufnr v]
  (let [commands []]
    (when (= v :true)
      (table.insert commands
                    {:events [:BufWritePre]
                     :targets [(string.format "<buffer=%d>" bufnr)]
                     :callback trim-whitespace}))
    (when (vim.api.nvim_buf_is_valid bufnr)
      (mod-invoke :fsouza.lib.nvim-helpers :augroup
                  (.. :editorconfig_trim_trailing_whitespace_ bufnr) commands))))

(fn set-opts [bufnr opts]
  (let [vim-opts {:tabstop 8}]
    (each [k v (pairs opts)]
      (match k
        :charset (handle-charset vim-opts v)
        :end_of_line (handle-eol vim-opts v)
        :indent_style (handle-indent-style vim-opts v)
        :insert_final_line (handle-insert-final-line vim-opts v)
        :insert_final_newline (handle-insert-final-line vim-opts v)
        :indent_size (handle-indent-size vim-opts v opts)
        :trim_trailing_whitespace (vim.schedule #(handle-whitespaces bufnr v))))
    (vim.schedule #(when (and (vim.api.nvim_buf_is_valid bufnr)
                              (. vim :bo bufnr :modifiable))
                     (each [option-name value (pairs vim-opts)]
                       (tset (. vim :bo bufnr) option-name value))))))

(fn modify-filename-if-needed [name bufnr]
  (let [ft-map {:python :.py
                :sh :.sh
                :ruby :.rb
                :query :.scm
                :bash :.sh
                :zsh :.zsh
                :javascript :.js}
        (_ ext) (mod-invoke :fsouza.pl.path :splitext name)]
    (if (not= ext "")
        name
        (let [ft (. vim :bo bufnr :filetype)
              ext (. ft-map ft)]
          (if ext
              (.. name ext)
              name)))))

(fn set-config [bufnr]
  (let [filename (vim.api.nvim_buf_get_name bufnr)]
    (when (and (?. vim :bo bufnr :modifiable)
               (not (?. vim :bo bufnr :readonly)) (not= filename ""))
      (let [filename (mod-invoke :fsouza.pl.path :abspath filename)
            filename (modify-filename-if-needed filename bufnr)]
        (mod-invoke :fsouza.lib.cmd :run :editorconfig {:args [filename]} nil
                    (fn [result]
                      (if (= result.exit-status 0)
                          (set-opts bufnr (parse-output result.stdout))
                          (vim.notify (string.format "failed to run editorconfig: %s"
                                                     (vim.inspect result))))))))))

(fn setup []
  (mod-invoke :fsouza.lib.nvim-helpers :augroup :editorconfig
              [{:events [:BufNewFile :BufReadPost :BufFilePost :FileType]
                :targets ["*"]
                :callback #(set-config $1.buf)}]))

{: setup}
