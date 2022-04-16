(import-macros {: if-nil : abuf : mod-invoke} :helpers)

(fn run [bufname]
  (let [dir (vim.fn.fnamemodify bufname ":h")]
    (vim.fn.mkdir dir :p)))

(fn register-for-buffer []
  (let [bufnr (if-nil (abuf) (vim.api.nvim_get_current_buf))
        bufname (vim.api.nvim_buf_get_name bufnr)]
    (when (not= "" bufname)
      (mod-invoke :fsouza.lib.nvim-helpers :augroup (.. :fsouza__mkdir_ bufnr)
                  [{:events [:BufWritePre]
                    :targets [(string.format "<buffer=%d>" bufnr)]
                    :once true
                    :callback #(run bufname)}]))))

(fn setup []
  (mod-invoke :fsouza.lib.nvim-helpers :augroup :fsouza__mkdir
              [{:events [:BufNew] :targets ["*"] :callback register-for-buffer}])
  (register-for-buffer))

{: setup}
