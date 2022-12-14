(import-macros {: if-nil : mod-invoke} :helpers)

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

(fn setup []
  (mod-invoke :fsouza.lib.nvim-helpers :augroup :fsouza__mkdir
              [{:events [:BufNew]
                :targets ["*"]
                :callback #(register-for-buffer $1.buf)}])
  (register-for-buffer (vim.api.nvim_get_current_buf)))

{: setup}
