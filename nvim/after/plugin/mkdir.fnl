(import-macros {: mod-invoke} :helpers)

(fn run [bufname]
  (let [dir (mod-invoke :fsouza.pl.path :dirname bufname)]
    (vim.fn.mkdir dir :p)))

(fn register-for-buffer [bufnr]
  (let [bufname (vim.api.nvim_buf_get_name bufnr)]
    (when (not= "" bufname)
      (mod-invoke :fsouza.lib.nvim-helpers :augroup (.. :fsouza__mkdir_ bufnr)
                  [{:events [:BufWritePre]
                    :targets [(string.format "<buffer=%d>" bufnr)]
                    :once true
                    :callback #(run bufname)}]))))

(do
  (mod-invoke :fsouza.lib.nvim-helpers :augroup :fsouza__mkdir
              [{:events [:BufNew]
                :targets ["*"]
                :callback #(register-for-buffer $1.buf)}])
  (each [_ bufnr (ipairs (vim.api.nvim_list_bufs))]
    (register-for-buffer bufnr)))
